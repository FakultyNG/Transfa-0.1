import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' show ImageFilter;

import '../../../core/constants/assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/pressable_scale.dart';

class FailedPopup extends StatefulWidget {
  const FailedPopup({
    super.key,
    required this.onTryAgain,
    required this.message,
  });

  final VoidCallback onTryAgain;
  final String message;

  @override
  State<FailedPopup> createState() => _FailedPopupState();
}

class _FailedPopupState extends State<FailedPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: 330,
                decoration: BoxDecoration(
                  color: const Color(0xB3FCFCFB),
                  borderRadius: BorderRadius.circular(56),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(56),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x20FFFFFF),
                        borderRadius: BorderRadius.circular(56),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 30),
                          SizedBox(
                            width: 300,
                            height: 300,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Gray face with not recognized icon
                                ClipOval(
                                  child: SizedBox(
                                    width: 220,
                                    height: 220,
                                    child: Center(
                                      child: SvgPicture.asset(
                                        Assets.notRecognized,
                                        width: 170,
                                        height: 170,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: SvgPicture.asset(
                                      Assets.blueBubbleIncomplete,
                                      width: 45,
                                      height: 45,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: SvgPicture.asset(
                                      Assets.yellowBubbleIncomplete,
                                      width: 45,
                                      height: 45,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 7,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: SvgPicture.asset(
                                      Assets.greenBubbleIncomplete,
                                      width: 195,
                                      height: 195,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 7,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: SvgPicture.asset(
                                      Assets.redBubbleIncomplete,
                                      width: 195,
                                      height: 195,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Face Shot',
                            style: TextStyle(
                              fontFamily: 'Arial Rounded MT Bold',
                              fontSize: 26,
                              letterSpacing: 0.02,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Text(
                              widget.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 17,
                                letterSpacing: 0.02,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(30, 0, 30, 30),
                            child: PressableScale(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  widget.onTryAgain();
                                },
                                child: Container(
                                  height: 58,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppColors.primaryLight,
                                        AppColors.primary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Try Again',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 17,
                                      letterSpacing: 0.02,
                                      color: Color(0xFFFCFCFB),
                                    ),
                                  ),
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
    );
  }
}
