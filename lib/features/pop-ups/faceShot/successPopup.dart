import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' show ImageFilter;
import 'dart:io';

import '../../../../core/constants/assets.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';

class SuccessPopup extends StatefulWidget {
  final File? capturedFaceImage;
  final String? capturedFaceImageUrl;
  const SuccessPopup({
    super.key,
    this.capturedFaceImage,
    this.capturedFaceImageUrl,
  });

  @override
  State<SuccessPopup> createState() => SuccessPopupState();
}

class SuccessPopupState extends State<SuccessPopup>
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
                                ClipOval(
                                  child: Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE9E9E9),
                                      image: _verifiedFaceImage(),
                                    ),
                                    child:
                                        widget.capturedFaceImage == null &&
                                            widget.capturedFaceImageUrl == null
                                        ? const Icon(
                                            Icons.verified_user_rounded,
                                            size: 96,
                                            color: AppColors.primary,
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: SvgPicture.asset(
                                      Assets.blueBubble,
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
                                      Assets.yellowBubble,
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
                                      Assets.greenBubble,
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
                                      Assets.redBubble,
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
                          const Text(
                            'Face Shot is complete.',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 17,
                              letterSpacing: 0.02,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(30, 0, 30, 30),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                                context.push(Routes.createPin);
                              },
                              child: Container(
                                width: 270,
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
                                  'Continue',
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

  DecorationImage? _verifiedFaceImage() {
    final file = widget.capturedFaceImage;
    if (file != null) {
      return DecorationImage(image: FileImage(file), fit: BoxFit.cover);
    }
    final url = widget.capturedFaceImageUrl;
    if (url != null && url.isNotEmpty) {
      return DecorationImage(image: NetworkImage(url), fit: BoxFit.cover);
    }
    return null;
  }
}
