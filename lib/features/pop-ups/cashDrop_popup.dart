import 'dart:convert';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/assets.dart';
import '../../core/router/routes.dart';
import '../../core/utils/error_messages.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/repositories.dart';
import '../transfers/presentation/transfer_state.dart';

enum _CashDropMode { receive, pay }

class CashDropScreen extends ConsumerStatefulWidget {
  const CashDropScreen({super.key});

  @override
  ConsumerState<CashDropScreen> createState() => _CashDropScreenState();
}

class _CashDropScreenState extends ConsumerState<CashDropScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();
  late final Animation<Offset> _slideAnimation =
      Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
      );
  late final Animation<double> _fadeAnimation = Tween<double>(
    begin: 0,
    end: 1,
  ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

  bool _loading = false;
  bool _initializingCamera = false;
  _CashDropMode _mode = _CashDropMode.receive;
  CameraController? _cameraController;

  @override
  void dispose() {
    _cameraController?.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    if (_cameraController?.value.isInitialized == true || _initializingCamera) {
      return;
    }
    setState(() => _initializingCamera = true);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera is available on this device.');
      }
      final selected = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      final controller = CameraController(
        selected.isNotEmpty ? selected.first : cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted || _mode != _CashDropMode.pay) {
        await controller.dispose();
        return;
      }
      setState(() => _cameraController = controller);
    } catch (error) {
      _message(userFacingError(error));
    } finally {
      if (mounted) setState(() => _initializingCamera = false);
    }
  }

  Future<void> _stopCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (mounted) setState(() {});
    await controller?.dispose();
  }

  Future<void> _selectReceive() async {
    if (_mode != _CashDropMode.receive) {
      setState(() => _mode = _CashDropMode.receive);
    }
    await _stopCamera();
    final status = ref.read(cashDropStatusProvider).valueOrNull;
    if (status?.enabled != true) await _setEnabled(true);
  }

  Future<void> _selectPay() async {
    if (_mode != _CashDropMode.pay) {
      setState(() => _mode = _CashDropMode.pay);
    }
    await _startCamera();
  }

  Future<void> _setEnabled(bool enabled) async {
    final config = await ref.read(cashDropConfigProvider.future);
    if (!config.featureEnabled) {
      _message('CashDrop is not available yet.');
      return;
    }
    setState(() => _loading = true);
    try {
      final repository = ref.read(deviceFeaturesRepositoryProvider);
      if (enabled) {
        await repository.registerCashDrop();
      } else {
        await repository.disableCashDrop();
      }
      ref.invalidate(cashDropStatusProvider);
    } catch (error) {
      _message(userFacingError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scan() async {
    final config = await ref.read(cashDropConfigProvider.future);
    if (!config.featureEnabled) {
      _message('CashDrop is not available yet.');
      return;
    }
    if (_mode != _CashDropMode.pay) {
      await _selectPay();
      return;
    }
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      await _startCamera();
      return;
    }
    setState(() => _loading = true);
    try {
      final image = await controller.takePicture();
      final bytes = await image.readAsBytes();
      final match = await ref
          .read(deviceFeaturesRepositoryProvider)
          .resolveCashDrop('data:image/jpeg;base64,${base64Encode(bytes)}');
      final suggestions = await ref
          .read(transferRepositoryProvider)
          .suggestBanks(match.accountNumber);
      final matchingBanks = suggestions.where(
        (item) => item.bankName.toLowerCase() == match.bankName.toLowerCase(),
      );
      final bank = matchingBanks.isNotEmpty
          ? matchingBanks.first
          : suggestions.isNotEmpty
          ? suggestions.first
          : null;
      if (bank == null) {
        throw StateError('The matched bank could not be resolved safely.');
      }
      ref.read(transferDraftProvider.notifier).state = TransferDraft(
        currency: TxCurrency.ngn,
        recipientName: match.displayName,
        recipientAccount: match.accountNumber,
        bankName: bank.bankName,
        bankCode: bank.bankCode,
      );
      if (!mounted) return;
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      router.push(Routes.amount);
    } catch (error) {
      _message(userFacingError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(cashDropConfigProvider);
    final status = ref.watch(cashDropStatusProvider);
    final user = ref.watch(currentUserProvider);
    final cashDrop = status.asData?.value;
    final profileUrl = cashDrop?.profileImageUrl ?? user?.avatarUrl;
    final error = config.hasError
        ? userFacingError(config.error!)
        : status.hasError
        ? userFacingError(status.error!)
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.black.withValues(alpha: 0.2)),
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: 350,
                    constraints: const BoxConstraints(maxHeight: 666),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFCFCFB),
                      borderRadius: BorderRadius.circular(56),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(56),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                        child: Material(
                          color: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    width: 50,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(35),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _mode == _CashDropMode.pay && !_loading
                                      ? _scan
                                      : null,
                                  child: _CashDropFace(
                                    profileUrl: profileUrl,
                                    cameraController: _mode == _CashDropMode.pay
                                        ? _cameraController
                                        : null,
                                    cameraLoading:
                                        _mode == _CashDropMode.pay &&
                                        _initializingCamera,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Transfa',
                                  style: const TextStyle(
                                    fontFamily: 'Arial Rounded MT Bold',
                                    fontSize: 30,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                  ),
                                  child: Text(
                                    error ??
                                        (_mode == _CashDropMode.receive
                                            ? 'To receive, scan your face with another Transfa'
                                            : 'To pay, try holding this Transfa over another Transfa'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 17,
                                      height: 1.5,
                                      letterSpacing: 0.02,
                                      color: error == null
                                          ? Colors.white.withValues(alpha: 0.5)
                                          : const Color(0xFFFF9F9F),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () => context.go(Routes.dashboard),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFFC30F),
                                              Color(0xFF9747FF),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            35,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: SvgPicture.asset(
                                          Assets.home,
                                          width: 26,
                                          height: 26,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 136,
                                      height: 50,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(35),
                                      ),
                                      child: Row(
                                        children: [
                                          _CashDropControl(
                                            active:
                                                _mode == _CashDropMode.receive,
                                            enabled: !_loading,
                                            onTap: _selectReceive,
                                            child: SvgPicture.asset(
                                              Assets.receive,
                                              width: 16,
                                              height: 20,
                                            ),
                                          ),
                                          _CashDropControl(
                                            active: _mode == _CashDropMode.pay,
                                            enabled: !_loading,
                                            onTap: _mode == _CashDropMode.pay
                                                ? _scan
                                                : _selectPay,
                                            child: SvgPicture.asset(
                                              Assets.cashDrop,
                                              width: 26,
                                              height: 26,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (_loading ||
                                    config.isLoading ||
                                    status.isLoading) ...[
                                  const SizedBox(height: 18),
                                  const LinearProgressIndicator(
                                    color: Color(0xFF00C2FF),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CashDropFace extends StatelessWidget {
  const _CashDropFace({
    this.profileUrl,
    this.cameraController,
    this.cameraLoading = false,
  });

  final String? profileUrl;
  final CameraController? cameraController;
  final bool cameraLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: Container(
              width: 190,
              height: 190,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF00BCF6), Color(0xFF006EFF)],
                ),
              ),
              child: cameraController?.value.isInitialized == true
                  ? _CashDropCameraPreview(controller: cameraController!)
                  : cameraLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : profileUrl == null || profileUrl!.isEmpty
                  ? const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 96,
                    )
                  : Image.network(
                      profileUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 96,
                      ),
                    ),
            ),
          ),
          Positioned(
            top: 10,
            child: SvgPicture.asset(Assets.blueBubble, width: 45, height: 45),
          ),
          Positioned(
            bottom: 10,
            child: SvgPicture.asset(Assets.yellowBubble, width: 45, height: 45),
          ),
          Positioned(
            left: 7,
            child: SvgPicture.asset(
              Assets.greenBubble,
              width: 195,
              height: 195,
            ),
          ),
          Positioned(
            right: 7,
            child: SvgPicture.asset(Assets.redBubble, width: 195, height: 195),
          ),
        ],
      ),
    );
  }
}

class _CashDropCameraPreview extends StatelessWidget {
  const _CashDropCameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return const SizedBox.shrink();

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: previewSize.height,
        height: previewSize.width,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _CashDropControl extends StatelessWidget {
  const _CashDropControl({
    required this.active,
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  final bool active;
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF00E9F8), Color(0xFF0D7BE1)],
                  )
                : null,
            borderRadius: BorderRadius.circular(35),
            color: active ? null : Colors.transparent,
          ),
          alignment: Alignment.center,
          foregroundDecoration: enabled
              ? null
              : BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(35),
                ),
          child: child,
        ),
      ),
    );
  }
}
