import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/user.dart';
import '../dashboard/presentation/share_account_screen.dart';

/// Displays the original account-details card and exports that exact widget as
/// a PNG through the platform share sheet.
class TransfaAccountSharePopup extends StatefulWidget {
  const TransfaAccountSharePopup({
    super.key,
    required this.user,
    required this.bankName,
    required this.accountNumber,
    this.shareOnOpen = true,
  });

  final AppUser? user;
  final String bankName;
  final String accountNumber;
  final bool shareOnOpen;

  @override
  State<TransfaAccountSharePopup> createState() =>
      TransfaAccountSharePopupState();
}

class TransfaAccountSharePopupState extends State<TransfaAccountSharePopup>
    with SingleTickerProviderStateMixin {
  final _shareCardKey = GlobalKey();
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _fadeAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );
    _slideController.forward();
    if (widget.shareOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepareAndShare());
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _prepareAndShare() async {
    final imageUrl = widget.user?.avatarUrl?.trim() ?? '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      try {
        await precacheImage(NetworkImage(imageUrl), context);
      } catch (_) {
        // The PNG still renders with the card's profile placeholder.
      }
    }
    await _slideController.forward();
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    await _shareCard();
  }

  Future<void> _shareCard() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary =
          _shareCardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Account card is unavailable');
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Account card could not be encoded');
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/transfa-account-details.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: 'My Transfa account details',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to share account image.')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: GestureDetector(
              onTap: _sharing ? null : _shareCard,
              child: RepaintBoundary(
                key: _shareCardKey,
                child: AccountShareCard(
                  user: widget.user,
                  bankName: widget.bankName,
                  accountNumber: widget.accountNumber,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
