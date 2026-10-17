import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/assets.dart';
import '../../../shared/widgets/transfa_logo.dart';
import '../../../data/mock_api/currency.dart';

// ============================================================
// CURRENCY POPUP (slides from top)
// ============================================================
class CurrencyPopup extends StatefulWidget {
  const CurrencyPopup();

  @override
  State<CurrencyPopup> createState() => CurrencyPopupState();
}

class CurrencyPopupState extends State<CurrencyPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

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
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
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
                              // Header Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      alignment: Alignment.center,
                                      child: const TransfaMark(
                                        size: 32,
                                        white: true,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      'Amount Currency',
                                      style: TextStyle(
                                        fontFamily: 'Arial Rounded MT Bold',
                                        fontSize: 20,
                                        letterSpacing: 0.02,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Select a currency to enter the amount. Transfa converts automatically.',
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w400,
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
                              // USD Option
                              _CurrencyOption(
                                flag: _UsFlag(),
                                label: 'Dollar',
                                currency: AmountCurrency.usd,
                              ),
                              const SizedBox(height: 10),
                              // NGN Option
                              _CurrencyOption(
                                flag: _NigeriaFlag(),
                                label: 'Naira',
                                currency: AmountCurrency.ngn,
                              ),
                              const SizedBox(height: 10),
                              // CNY Option
                              _CurrencyOption(
                                flag: _ChinaFlag(),
                                label: 'Yuan',
                                currency: AmountCurrency.cny,
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
    );
  }
}

class _CurrencyOption extends StatelessWidget {
  final Widget flag;
  final String label;
  final AmountCurrency currency;

  const _CurrencyOption({
    required this.flag,
    required this.label,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (currency == AmountCurrency.ngn) {
          Navigator.of(context).pop(currency);
          return;
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$label is coming soon.')));
      },
      child: Container(
        width: double.infinity,
        height: 56, // Fixed height for all options
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x1AFCFCFB),
          borderRadius: BorderRadius.circular(35),
        ),
        child: Row(
          children: [
            // Flag container - consistent size for all
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
              ),
              child: Center(child: flag),
            ),
            const SizedBox(width: 12),
            // Label - consistent positioning
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  fontSize: 17,
                  letterSpacing: 0.02,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NigeriaFlag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 24,
        child: SvgPicture.asset(
          Assets.Nigerian_Flag,
          width: 32,
          height: 24,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _UsFlag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 24,
        child: SvgPicture.asset(
          Assets.spendCurrency,
          width: 32,
          height: 24,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _ChinaFlag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 24,
        child: SvgPicture.asset(
          Assets.China_Flag,
          width: 32,
          height: 24,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
