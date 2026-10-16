// lib/features/pop-ups/bank_unavailable_popup.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/assets.dart';

/// Bank Unavailable Popup with slide animations (matching Currency Popup style)
class BankUnavailablePopup extends StatefulWidget {
  final String bankName;
  final VoidCallback? onContinueWithTransfa;
  final VoidCallback? onClose;

  const BankUnavailablePopup({
    super.key,
    required this.bankName,
    this.onContinueWithTransfa,
    this.onClose,
  });

  @override
  State<BankUnavailablePopup> createState() => _BankUnavailablePopupState();
}

class _BankUnavailablePopupState extends State<BankUnavailablePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  bool _isTransfaSelected = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> closeWithAnimation() async {
    if (_animationController.isAnimating) return;

    await _animationController.reverse();

    if (mounted) {
      widget.onClose?.call();
      Navigator.of(context).pop();
    }
  }

  void _toggleTransfa() {
    setState(() {
      _isTransfaSelected = !_isTransfaSelected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await closeWithAnimation();
        }
      },
      child: GestureDetector(
        onTap: closeWithAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 270,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(108, 163, 163, 163),
                    borderRadius: BorderRadius.circular(45),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(45),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0x20FFFFFF),
                            borderRadius: BorderRadius.circular(45),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header Section
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,

                                        alignment: Alignment.center,
                                        child: SvgPicture.asset(
                                          Assets.networkUnavailable,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      const Text(
                                        'Bank Unavailable',
                                        style: TextStyle(
                                          fontFamily: 'Arial Rounded MT Bold',
                                          fontSize: 20,
                                          letterSpacing: 0.02,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'The money could not be sent because "${widget.bankName}" is unavailable.',
                                        style: const TextStyle(
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 15,
                                          height: 1.5,
                                          letterSpacing: 0.02,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Continue with Transfa?',
                                        style: TextStyle(
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                          height: 1.5,
                                          letterSpacing: 0.02,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Transfa Option with Toggle
                                GestureDetector(
                                  onTap: _toggleTransfa,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x1AFCFCFB),
                                      borderRadius: BorderRadius.circular(35),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius: BorderRadius.circular(
                                              35,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: SvgPicture.asset(
                                            Assets.transfaLife,
                                            width: 20,
                                            height: 20,
                                            fit: BoxFit.contain,
                                            colorFilter: const ColorFilter.mode(
                                              Colors.white,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Expanded(
                                          child: Text(
                                            'Transfa',
                                            style: TextStyle(
                                              fontFamily: 'Roboto',
                                              fontWeight: FontWeight.w400,
                                              fontSize: 17,
                                              letterSpacing: 0.02,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        SvgPicture.asset(
                                          _isTransfaSelected
                                              ? Assets.checkGreen
                                              : "",
                                          width: 26,
                                          height: 26,
                                          fit: BoxFit.contain,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Continue Button
                                GestureDetector(
                                  onTap: () {
                                    if (_isTransfaSelected) {
                                      widget.onContinueWithTransfa?.call();
                                    }
                                    closeWithAnimation();
                                  },
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFFFF4466),
                                          Color(0xFFF41E42),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(35),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _isTransfaSelected
                                          ? 'Continue'
                                          : 'Cancel',
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 17,
                                        height: 1.5,
                                        letterSpacing: 0.02,
                                        color: Color(0xFFFCFCFB),
                                      ),
                                    ),
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
        ),
      ),
    );
  }
}

/// Helper method to show the bank unavailable popup
Future<void> showBankUnavailablePopup(
  BuildContext context, {
  required String bankName,
  VoidCallback? onContinueWithTransfa,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    useRootNavigator: true,
    builder: (dialogContext) => BankUnavailablePopup(
      bankName: bankName,
      onContinueWithTransfa: onContinueWithTransfa,
      onClose: () {},
    ),
  );
}
