import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/assets.dart';
import '../../core/router/routes.dart';

// ============================================================
// TRANSFA DONE POPUP (slides from top)
// ============================================================
class TransfaDonePopup extends StatefulWidget {
  final VoidCallback? onClose;
  final String? userImageUrl;
  final String userName;
  final bool navigateToReceipt;

  const TransfaDonePopup({
    super.key,
    this.onClose,
    this.userImageUrl,
    required this.userName,
    this.navigateToReceipt = true,
  });

  @override
  State<TransfaDonePopup> createState() => _TransfaDonePopupState();
}

class _TransfaDonePopupState extends State<TransfaDonePopup>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();

    // Auto close after 2 seconds and navigate to receipt
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isNavigating) {
        _isNavigating = true;
        // Close the popup first
        Navigator.of(context).pop();
        // Then navigate to receipt screen using GoRouter
        if (widget.navigateToReceipt) context.go(Routes.receiptInReview);
        widget.onClose?.call();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_isNavigating) {
          _isNavigating = true;
          Navigator.of(context).pop();
          if (widget.navigateToReceipt) context.go(Routes.receiptInReview);
          widget.onClose?.call();
        }
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF07B826), Color(0xFF4EE659)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Face Shot Now
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(35),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(35),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF00BCF6),
                                        Color(0xFF006EFF),
                                      ],
                                    ),
                                  ),
                                  child:
                                      widget.userImageUrl != null &&
                                          widget.userImageUrl!.isNotEmpty
                                      ? widget.userImageUrl!.startsWith('http')
                                            ? Image.network(
                                                widget.userImageUrl!,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.asset(
                                                widget.userImageUrl!,
                                                fit: BoxFit.cover,
                                              )
                                      : Center(
                                          child: Text(
                                            widget.userName.isNotEmpty
                                                ? widget.userName[0]
                                                      .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontFamily:
                                                  'Arial Rounded MT Bold',
                                              fontSize: 24,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Transfa Status
                            Container(
                              width: 80,
                              height: 16,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Transfa CHECKS
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(35),
                                    ),
                                    child: Stack(
                                      children: [
                                        // DONE CHECK BOX
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: const Color(0xFFFCFCFB),
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              40,
                                            ),
                                          ),
                                        ),
                                        // CHECK
                                        Center(
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            child: SvgPicture.asset(
                                              Assets.check,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Done Text
                                  const Text(
                                    'Done',
                                    style: TextStyle(
                                      fontFamily: 'Arial Rounded MT Bold',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                      height: 1.2,
                                      letterSpacing: 0.02,
                                      color: Color(0xFFFCFCFB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
    );
  }
}
