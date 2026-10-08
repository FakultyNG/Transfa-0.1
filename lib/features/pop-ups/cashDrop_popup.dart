import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/assets.dart';
import '../../../core/router/routes.dart';

class CashDropScreen extends StatefulWidget {
  const CashDropScreen({super.key});

  @override
  State<CashDropScreen> createState() => _CashDropScreenState();
}

class _CashDropScreenState extends State<CashDropScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPopupVisible = true;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _closePopup() {
    setState(() {
      _isPopupVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Content (visible after popup closes)
          if (!_isPopupVisible)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              child: const Center(
                child: Text(
                  'CashDrop Content',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          // Blur overlay when popup is visible
          if (_isPopupVisible)
            GestureDetector(
              onTap: _closePopup,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          // Popup
          if (_isPopupVisible)
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: 350,
                        height: 666,
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
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.02),
                                  borderRadius: BorderRadius.circular(56),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 20),
                                    // Dynamic Island (tappable to close)
                                    GestureDetector(
                                      onTap: _closePopup,
                                      child: Container(
                                        width: 50,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(35),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    // First Name & Face Shot
                                    Column(
                                      children: [
                                        // CashDrop Face with Bubbles
                                        SizedBox(
                                          width: 250,
                                          height: 250,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Face circle
                                              ClipOval(
                                                child: Container(
                                                  width: 190,
                                                  height: 190,
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                      colors: [Color(0xFF00BCF6), Color(0xFF006EFF)],
                                                    ),
                                                    image: const DecorationImage(
                                                      image: AssetImage(Assets.magic),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Blue bubble - Top
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
                                              // Yellow bubble - Bottom
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
                                              // Green bubble - Left
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
                                              // Red bubble - Right
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
                                        // Magic Text
                                        Material(
                                          color: Colors.transparent,
                                          child: Text(
                                            'Magic',
                                            style: const TextStyle(
                                              fontFamily: 'Arial Rounded MT Bold',
                                              fontSize: 30,
                                              letterSpacing: 0.02,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 40),
                                    // Navigation
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 30),
                                      child: Column(
                                        children: [
                                          Material(
                                            color: Colors.transparent,
                                            child: Text(
                                              'To receive, scan your face with another Transfa.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Roboto',
                                                fontWeight: FontWeight.w400,
                                                fontSize: 17,
                                                height: 1.5,
                                                letterSpacing: 0.02,
                                                color: Colors.white.withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          // CashDrop Navigation
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Home Sweet Home
                                              GestureDetector(
                                                onTap: () => context.pop(),
                                                child: Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFFFFC30F), Color(0xFF9747FF)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(35),
                                                  ),
                                                  child: Center(
                                                    child: SvgPicture.asset(
                                                      Assets.home,
                                                      width: 26,
                                                      height: 26,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // CashDrop Navigation Row
                                              Container(
                                                width: 136,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(35),
                                                ),
                                                child: Row(
                                                  children: [
                                                    // Receiving from Everyone
                                                    Container(
                                                      width: 62,
                                                      height: 42,
                                                      decoration: BoxDecoration(
                                                        gradient: const LinearGradient(
                                                          colors: [Color(0xFF00E9F8), Color(0xFF0D7BE1)],
                                                        ),
                                                        borderRadius: BorderRadius.circular(35),
                                                      ),
                                                      child: Center(
                                                        child: SvgPicture.asset(
                                                          Assets.receive,
                                                          width: 16,
                                                          height: 20,
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    ),
                                                    // CashDrop Off
                                                    Container(
                                                      width: 62,
                                                      height: 42,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(35),
                                                      ),
                                                      child: Center(
                                                        child: SvgPicture.asset(
                                                          Assets.cashDrop,
                                                          width: 26,
                                                          height: 26,
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 30),
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
        ],
      ),
    );
  }
}