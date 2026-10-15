import 'dart:convert';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image_lib;
import 'dart:io';
import 'dart:async';

import '../../../core/constants/assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/repositories/repositories.dart';
import '../../pop-ups/faceShot/failedPopup.dart';
import '../../pop-ups/faceShot/faceShotPopup.dart';
import '../../pop-ups/faceShot/successPopup.dart';
import 'bytid_liveness_screen.dart';

List<CameraDescription>? cameras;

class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  File? _capturedFaceImage;
  bool _isFaceCaptured = false;
  bool _isCapturing = false;
  bool _isVerifying = false;
  Timer? _captureTimer;
  CameraController? _cameraController;
  Future<void>? _cameraInitialization;
  bool _isCameraInitialized = false;
  int? _countdownRemaining;
  StreamSubscription<Uri>? _deepLinkSubscription;
  Timer? _livenessPollTimer;
  String? _livenessSessionId;
  String? _verifiedProfileImageUrl;
  String? _profileImageBase64;
  bool _isCheckingLiveness = false;
  bool _livenessStarted = false;

  bool get _usesLiveness =>
      ref.read(registrationSessionProvider)?.selfieMode == 'bytid_liveness';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _deepLinkSubscription = AppLinks().uriLinkStream.listen(_handleDeepLink);
    _cameraInitialization = _initCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFaceShotPopup();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _captureTimer?.cancel();
    _livenessPollTimer?.cancel();
    _deepLinkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _usesLiveness &&
        _livenessSessionId != null) {
      _completeLiveness();
    }
  }

  Future<void> _initCamera() async {
    if (cameras == null || cameras!.isEmpty) {
      cameras = await availableCameras();
    }

    final frontCamera = cameras!.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras!.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController!.initialize();
    await _configureCameraForFaceCapture(_cameraController!);
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _configureCameraForFaceCapture(
    CameraController controller,
  ) async {
    try {
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    } on CameraException catch (error) {
      debugPrint('Capture orientation is not supported: $error');
    }
    try {
      await controller.setFlashMode(FlashMode.off);
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      await controller.setFocusPoint(const Offset(0.5, 0.5));
      await controller.setExposurePoint(const Offset(0.5, 0.5));
    } on CameraException catch (error) {
      debugPrint('Camera focus/exposure control is not supported: $error');
    }
  }

  void _showFaceShotPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const FaceShotPopup(),
    ).then((_) {
      if (mounted && !_isFaceCaptured && !_isCapturing) {
        _startAutoCapture();
      }
    });
  }

  Future<void> _startLiveness() async {
    if (_livenessStarted || _isVerifying) return;
    final session = ref.read(registrationSessionProvider);
    if (session?.registrationToken == null || session?.kycReference == null) {
      _showFailedPopup('KYC session expired. Start registration again.');
      return;
    }
    if (_profileImageBase64 == null) {
      _showFailedPopup(
        'Take a profile photo before starting the live face check.',
      );
      return;
    }
    setState(() {
      _livenessStarted = true;
      _isVerifying = true;
      _isCapturing = false;
    });
    try {
      final liveness = await ref
          .read(authRepositoryProvider)
          .startBvnLiveness(
            registrationToken: session!.registrationToken!,
            kycReference: session.kycReference!,
          );
      _livenessSessionId = liveness.id;
      if (!mounted) return;
      final result = await Navigator.of(context).push<LivenessWebResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => BytidLivenessScreen(
            sessionUrl: liveness.url,
            sessionId: liveness.id,
          ),
        ),
      );
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _isVerifying = false;
          _livenessStarted = false;
        });
        return;
      }
      _livenessPollTimer?.cancel();
      _livenessPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        _completeLiveness();
      });
      await _completeLiveness();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _livenessStarted = false;
      });
      _showFailedPopup(userFacingError(error));
    }
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'transfa' ||
        uri.host != 'kyc' ||
        uri.path != '/liveness-complete') {
      return;
    }
    final returnedId = uri.queryParameters['liveness_session_id'];
    if (returnedId == null || returnedId != _livenessSessionId) return;
    _completeLiveness();
  }

  Future<void> _completeLiveness() async {
    if (_isCheckingLiveness || _livenessSessionId == null) return;
    final session = ref.read(registrationSessionProvider);
    if (session?.registrationToken == null || session?.kycReference == null) {
      return;
    }
    _isCheckingLiveness = true;
    try {
      final status = await ref
          .read(authRepositoryProvider)
          .getBvnLivenessStatus(
            registrationToken: session!.registrationToken!,
            kycReference: session.kycReference!,
            livenessSessionId: _livenessSessionId!,
          );
      if (!mounted) return;
      if (status.status == 'pending') {
        setState(() => _isVerifying = true);
        return;
      }
      if (status.status != 'passed' || !status.usableForFaceMatch) {
        _livenessPollTimer?.cancel();
        setState(() => _isVerifying = false);
        final details = status.reasons
            .map((reason) => reason.replaceAll('_', ' '))
            .join(', ');
        _showFailedPopup(
          details.isEmpty
              ? 'The live face check ${status.status}. Please try again.'
              : 'The live face check failed: $details.',
        );
        return;
      }

      final verification = await ref
          .read(authRepositoryProvider)
          .completeBvnLiveness(
            registrationToken: session.registrationToken!,
            kycReference: session.kycReference!,
            livenessSessionId: _livenessSessionId!,
            profileImageBase64: _profileImageBase64!,
          );
      if (!mounted) return;
      if (verification.kycStatus == 'pending') {
        setState(() => _isVerifying = true);
        return;
      }
      _livenessPollTimer?.cancel();
      setState(() => _isVerifying = false);
      if (verification.isVerified && verification.livenessStatus == 'passed') {
        _verifiedProfileImageUrl = verification.profileImageUrl;
        _showSuccessPopup();
      } else {
        _showFailedPopup(
          verification.faceMatchReason ??
              _fallbackFailureMessage(verification.faceMatchStatus),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    } finally {
      _isCheckingLiveness = false;
    }
  }

  void _startAutoCapture() {
    _captureTimer?.cancel();
    final session = ref.read(registrationSessionProvider);
    final countdownEnabled = session?.selfieCountdownEnabled ?? true;
    final countdownSeconds = (session?.selfieCountdownSeconds ?? 5).clamp(
      1,
      10,
    );
    setState(() {
      _isCapturing = true;
      _countdownRemaining = countdownEnabled ? countdownSeconds : null;
    });
    if (!countdownEnabled) {
      Future<void>.microtask(_captureFace);
      return;
    }
    _captureTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _countdownRemaining ?? 1;
      if (remaining <= 1) {
        timer.cancel();
        setState(() => _countdownRemaining = null);
        _captureFace();
      } else {
        setState(() => _countdownRemaining = remaining - 1);
      }
    });
  }

  Future<void> _captureFace() async {
    try {
      await _cameraInitialization;
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        if (mounted) setState(() => _isCapturing = false);
        return;
      }
      final xFile = await _cameraController!.takePicture();
      final File image = File(xFile.path);

      if (!mounted) return;
      setState(() {
        _capturedFaceImage = image;
        _isFaceCaptured = true;
        _isCapturing = false;
        _isVerifying = true;
        _countdownRemaining = null;
      });

      _captureTimer?.cancel();

      final session = ref.read(registrationSessionProvider);
      if (session?.registrationToken == null || session?.kycReference == null) {
        throw StateError('KYC session expired. Start registration again.');
      }
      final bytes = await _normalizedSelfieBytes(image);
      final selfie = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      if (_usesLiveness) {
        _profileImageBase64 = selfie;
        if (mounted) setState(() => _isVerifying = false);
        await _startLiveness();
        return;
      }
      final verification = await ref
          .read(authRepositoryProvider)
          .validateBvnSelfie(
            registrationToken: session!.registrationToken!,
            kycReference: session.kycReference!,
            selfieImageBase64: selfie,
          );

      if (!mounted) return;
      setState(() {
        _isVerifying = false;
      });

      if (verification.isVerified) {
        _showSuccessPopup();
      } else {
        _showFailedPopup(
          verification.faceMatchReason ??
              _fallbackFailureMessage(verification.faceMatchStatus),
        );
      }
    } catch (error) {
      debugPrint('Error capturing face: $error');
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _isVerifying = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
      _showFailedPopup(userFacingError(error));
    }
  }

  Future<List<int>> _normalizedSelfieBytes(File image) async {
    final bytes = await image.readAsBytes();
    final decoded = image_lib.decodeImage(bytes);
    if (decoded == null) return bytes;

    var normalized = image_lib.bakeOrientation(decoded);
    const maximumSide = 1600;
    if (normalized.width > maximumSide || normalized.height > maximumSide) {
      if (normalized.width >= normalized.height) {
        normalized = image_lib.copyResize(normalized, width: maximumSide);
      } else {
        normalized = image_lib.copyResize(normalized, height: maximumSide);
      }
    }
    var encoded = image_lib.encodeJpg(normalized, quality: 92);
    const uploadLimit = 1900 * 1024;
    if (encoded.length > uploadLimit) {
      if (normalized.width >= normalized.height && normalized.width > 1280) {
        normalized = image_lib.copyResize(normalized, width: 1280);
      } else if (normalized.height > 1280) {
        normalized = image_lib.copyResize(normalized, height: 1280);
      }
      encoded = image_lib.encodeJpg(normalized, quality: 85);
    }
    return encoded;
  }

  String _fallbackFailureMessage(String? status) {
    if (status == 'unavailable') {
      return 'No usable face was found in the selfie or BVN record. Keep your full face visible in bright, even lighting and try again.';
    }
    return 'The selfie did not match the photograph held against this BVN. Remove glasses or face coverings, face the camera directly, and try again.';
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => SuccessPopup(
        capturedFaceImage: _capturedFaceImage,
        capturedFaceImageUrl: _verifiedProfileImageUrl,
      ),
    );
  }

  void _showFailedPopup(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) =>
          FailedPopup(onTryAgain: _retryCapture, message: message),
    );
  }

  void _retryCapture() {
    _captureTimer?.cancel();
    setState(() {
      _capturedFaceImage = null;
      _isFaceCaptured = false;
      _isCapturing = false;
      _isVerifying = false;
      _countdownRemaining = null;
      _livenessSessionId = null;
      _verifiedProfileImageUrl = null;
      _profileImageBase64 = null;
      _livenessStarted = false;
    });
    _startAutoCapture();
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController!;
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return const SizedBox.shrink();
    return ClipOval(
      child: SizedBox(
        width: 250,
        height: 250,
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 28),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, _) => CustomPaint(
                          size: const Size(320, 320),
                          painter: _DottedFacePainter(
                            progress: _pulse.value,
                            isFaceCaptured: _isFaceCaptured,
                          ),
                        ),
                      ),
                      if (_isVerifying)
                        const SizedBox(
                          width: 250,
                          height: 250,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_isCapturing && _isCameraInitialized)
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildCameraPreview(),
                            if (_countdownRemaining != null)
                              Container(
                                width: 72,
                                height: 72,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$_countdownRemaining',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        )
                      else if (_capturedFaceImage != null)
                        ClipOval(
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: FileImage(_capturedFaceImage!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      // if (_isCapturing)
                      //   Container(
                      //     width: 220,
                      //     height: 220,
                      //     decoration: const BoxDecoration(
                      //       shape: BoxShape.circle,
                      //     ),
                      //     child: const Center(
                      //       child: CircularProgressIndicator(
                      //         color: Color.fromARGB(255, 236, 235, 236),
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Follow the light, move your\nhead slowly to complete the\ncircle.',
                    textAlign: TextAlign.center,
                    style: AppTypography.headingLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: SvgPicture.asset(
                            Assets.transfaYou,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showFaceShotPopup(),
                          child: RichText(
                            text: TextSpan(
                              style: AppTypography.body.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 15,
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(
                                  text:
                                      'Face Shot will recognize the unique features of your face to verify your identity & keep your Transfa secure. ',
                                ),
                                TextSpan(
                                  text: 'See how to take Pro Face Shots…',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _showFaceShotPopup(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DottedFacePainter extends CustomPainter {
  final double progress;
  final bool isFaceCaptured;

  _DottedFacePainter({required this.progress, required this.isFaceCaptured});

  static const _colors = [
    AppColors.success,
    Color(0xFFFF9F0A),
    Color(0xFFFF375F),
    Color(0xFFAF52DE),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    const total = 40;
    final paintDot = Paint()..color = const Color(0xFFDFDFDF);
    final anchorIdx = [
      (5 + (progress * 0.5 * total).round()) % total,
      (15 + (progress * 0.5 * total).round()) % total,
      (25 + (progress * 0.5 * total).round()) % total,
      (35 + (progress * 0.5 * total).round()) % total,
    ];

    for (var i = 0; i < total; i++) {
      final angle = -pi / 2 + (i / total) * 2 * pi;
      final dotCenter = Offset(c.dx + r * cos(angle), c.dy + r * sin(angle));
      final anchor = anchorIdx.indexOf(i);
      if (anchor >= 0) {
        final p = Paint()..color = _colors[anchor];
        canvas.drawCircle(dotCenter, 7, p);
      } else {
        canvas.drawCircle(dotCenter, 5, paintDot);
      }
    }

    if (!isFaceCaptured) {
      canvas.drawCircle(c, r - 18, Paint()..color = const Color(0xFFE9E9E9));
    }
  }

  @override
  bool shouldRepaint(covariant _DottedFacePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isFaceCaptured != isFaceCaptured;
  }
}
