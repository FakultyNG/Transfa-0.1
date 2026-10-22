import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/assets.dart';
import '../../../data/models/bank.dart';
import '../../../shared/widgets/transfa_logo.dart';

// ============================================================
// MULTIPLE BANKS POPUP
// ============================================================

class MultipleBanksPopup extends StatefulWidget {
  const MultipleBanksPopup({
    super.key,
    this.accountNumber,
    this.suggestions = const [],
  });

  final String? accountNumber;
  final List<BankSuggestion> suggestions;

  @override
  State<MultipleBanksPopup> createState() => _MultipleBanksPopupState();
}

class _MultipleBanksPopupState extends State<MultipleBanksPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String get _accountName => widget.suggestions.isEmpty
      ? 'Choose a bank'
      : widget.suggestions.first.accountName;

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
                width: 378,
                height: 560,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFCFB).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(45),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(45),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: const TransfaMark(
                                    size: 16,
                                    white: true,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Transfa',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 24,
                                      letterSpacing: 0.02,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFCFCFB,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(35),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Scrollable content
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  // Face Shot, Name & Account Number
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          width: 120,
                                          height: 120,

                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              120,
                                            ),
                                            child: Container(
                                              color: const Color(0xFFF1F1F3),
                                              alignment: Alignment.center,
                                              child: SvgPicture.asset(
                                                Assets.contacts,
                                                width: 54,
                                                height: 54,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          _accountName,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontFamily: 'Arial Rounded MT Bold',
                                            fontSize: 30,
                                            letterSpacing: 0.02,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        widget.accountNumber != null
                                            ? Text(
                                                widget.accountNumber!,
                                                style: const TextStyle(
                                                  fontFamily: 'Roboto',
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 17,
                                                  letterSpacing: 0.02,
                                                  color: Colors.black54,
                                                ),
                                              )
                                            : const SizedBox(height: 0),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Choose a Bank section
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFCFCFB),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Column(
                                      children: [
                                        // Navigation Note
                                        widget.accountNumber != null
                                            ? Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: const Text(
                                                  'This account number is connected to multiple banks, choose a bank to pay.',
                                                  style: TextStyle(
                                                    fontFamily: 'Roboto',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 16,
                                                    letterSpacing: 0.02,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: const Text(
                                                  'Enter an account number to find its most likely banks.',
                                                  style: TextStyle(
                                                    fontFamily: 'Roboto',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 16,
                                                    letterSpacing: 0.02,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                        const SizedBox(height: 10),

                                        if (widget.suggestions.isEmpty)
                                          const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Text(
                                              'No likely bank was found.',
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        else
                                          ...widget.suggestions.indexed.expand(
                                            (entry) => [
                                              _BankOption(
                                                logo: _bankLogo(entry.$2),
                                                name: entry.$2.bankName,
                                                onTap: () => Navigator.of(
                                                  context,
                                                ).pop(entry.$2),
                                              ),
                                              if (entry.$1 <
                                                  widget.suggestions.length - 1)
                                                const Divider(
                                                  height: 1,
                                                  color: Color(0xFFF0F0F0),
                                                ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),
                                ],
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

  Widget _bankLogo(BankSuggestion suggestion) {
    final words = suggestion.bankName
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = words.take(2).map((word) => word[0]).join().toUpperCase();
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: Color(0xFF18C83E),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BankOption extends StatelessWidget {
  final Widget logo;
  final String name;
  final VoidCallback onTap;

  const _BankOption({
    required this.logo,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Row(
          children: [
            logo,
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  fontSize: 17,
                  letterSpacing: 0.02,
                  color: Colors.black,
                ),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              child: SvgPicture.asset(Assets.forward, width: 10, height: 6),
            ),
          ],
        ),
      ),
    );
  }
}
