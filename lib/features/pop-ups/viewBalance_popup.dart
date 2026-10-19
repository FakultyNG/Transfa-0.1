import 'dart:ui';
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/assets.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/user.dart';
import '../../../data/models/wallet.dart';
import '../dashboard/presentation/share_account_screen.dart';

class ViewBalancePopup extends StatefulWidget {
  final AppUser? user;
  final num balance;
  final DedicatedVirtualAccount dva;
  final VoidCallback onCashDropTap;

  const ViewBalancePopup({
    super.key,
    required this.user,
    required this.balance,
    required this.dva,
    required this.onCashDropTap,
  });

  @override
  State<ViewBalancePopup> createState() => _ViewBalancePopupState();
}

class _ViewBalancePopupState extends State<ViewBalancePopup>
    with SingleTickerProviderStateMixin {
  final _shareCardKey = GlobalKey();
  bool _renderShareCard = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String _formatBalance(num amount) {
    final formatted = AppFormat.ngn(amount);
    // Remove cents if present
    if (formatted.contains('.')) {
      return formatted.split('.').first;
    }
    return formatted;
  }

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

  Future<void> _shareAccountCard() async {
    try {
      final avatarUrl = widget.user?.avatarUrl;
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        try {
          await precacheImage(NetworkImage(avatarUrl), context);
        } catch (_) {
          // The card still shares with its profile placeholder if the remote
          // image cannot be downloaded.
        }
      }
      if (!mounted) return;
      setState(() => _renderShareCard = true);
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final boundary =
          _shareCardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      if (bytes == null) return;
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/transfa-account.png');
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
      if (mounted) setState(() => _renderShareCard = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Container(
                      width: 340,
                      decoration: BoxDecoration(
                        color: const Color(0x1AFCFCFB),
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 20),
                                  Container(
                                    width: 290,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        14,
                                        252,
                                        252,
                                        251,
                                      ),
                                      borderRadius: BorderRadius.circular(45),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(35),
                                                  gradient:
                                                      const LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        colors: [
                                                          Color(0xFF00BCF6),
                                                          Color(0xFF006EFF),
                                                        ],
                                                      ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(35),
                                                  child:
                                                      widget.user?.avatarUrl ==
                                                              null ||
                                                          widget
                                                              .user!
                                                              .avatarUrl!
                                                              .isEmpty
                                                      ? const Icon(
                                                          Icons.person_rounded,
                                                          color: Colors.white,
                                                          size: 34,
                                                        )
                                                      : Image.network(
                                                          widget
                                                              .user!
                                                              .avatarUrl!,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (
                                                                _,
                                                                _,
                                                                _,
                                                              ) => const Icon(
                                                                Icons
                                                                    .person_rounded,
                                                                color: Colors
                                                                    .white,
                                                                size: 34,
                                                              ),
                                                        ),
                                                ),
                                              ),
                                              const SizedBox(width: 20),
                                              Expanded(
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: Text(
                                                    widget.user?.fullName ??
                                                        'Magic',
                                                    style: const TextStyle(
                                                      fontFamily: 'Roboto',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 17,
                                                      letterSpacing: 0.02,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.004,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(35),
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Transfa Balance',
                                                    style: TextStyle(
                                                      fontFamily: 'Roboto',
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      fontSize: 14,
                                                      letterSpacing: 0.02,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _formatBalance(
                                                      widget.balance,
                                                    ),
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'Arial Rounded MT Bold',
                                                      fontSize: 30,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 20,
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: SvgPicture.asset(
                                                  Assets.receive,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Expanded(
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: Text(
                                                    'Add Money to',
                                                    style: TextStyle(
                                                      fontFamily: 'Roboto',
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      fontSize: 15,
                                                      letterSpacing: 0.02,
                                                      color: Color.fromARGB(
                                                        255,
                                                        185,
                                                        185,
                                                        185,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.04,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.1,
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              45,
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Center(
                                                    child: SvgPicture.asset(
                                                      Assets.transfaLife,
                                                      width: 16,
                                                      height: 20,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        widget.dva.bankName,
                                                        style: TextStyle(
                                                          fontFamily: 'Roboto',
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 15,
                                                          letterSpacing: 0.02,
                                                          color: Color.fromARGB(
                                                            255,
                                                            185,
                                                            185,
                                                            185,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        widget
                                                            .dva
                                                            .accountNumber,
                                                        style: TextStyle(
                                                          fontFamily: 'Roboto',
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 17,
                                                          letterSpacing: 0.02,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Copy
                                              GestureDetector(
                                                onTap: () async {
                                                  await Clipboard.setData(
                                                    ClipboardData(
                                                      text: widget
                                                          .dva
                                                          .accountNumber,
                                                    ),
                                                  );
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Account number copied',
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              35,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: SvgPicture.asset(
                                                          Assets.copyWhite,
                                                          width: 20,
                                                          height: 20,
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    const Material(
                                                      color: Colors.transparent,
                                                      child: Text(
                                                        'Copy',
                                                        style: TextStyle(
                                                          fontFamily: 'Roboto',
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 13,
                                                          letterSpacing: 0.02,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Share
                                              GestureDetector(
                                                onTap: _shareAccountCard,
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                              colors: [
                                                                Color(
                                                                  0xFFFF7088,
                                                                ),
                                                                Color(
                                                                  0xFFF41E42,
                                                                ),
                                                              ],
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              35,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: SvgPicture.asset(
                                                          Assets.shareWhite,
                                                          width: 20,
                                                          height: 20,
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    const Material(
                                                      color: Colors.transparent,
                                                      child: Text(
                                                        'Share',
                                                        style: TextStyle(
                                                          fontFamily: 'Roboto',
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 13,
                                                          letterSpacing: 0.02,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // CashDrop
                                              GestureDetector(
                                                onTap: widget.onCashDropTap,
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                              colors: [
                                                                Color(
                                                                  0xFF00E9F8,
                                                                ),
                                                                Color(
                                                                  0xFF0D7BE1,
                                                                ),
                                                              ],
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              35,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: SvgPicture.asset(
                                                          Assets.cashDrop,
                                                          width: 20,
                                                          height: 20,
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    const Material(
                                                      color: Colors.transparent,
                                                      child: Text(
                                                        'CashDrop',
                                                        style: TextStyle(
                                                          fontFamily: 'Roboto',
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 13,
                                                          letterSpacing: 0.02,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
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
              if (_renderShareCard)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.001,
                      child: Center(
                        child: OverflowBox(
                          maxWidth: 340,
                          maxHeight: 700,
                          child: RepaintBoundary(
                            key: _shareCardKey,
                            child: AccountShareCard(
                              user: widget.user,
                              bankName: widget.dva.bankName,
                              accountNumber: widget.dva.accountNumber,
                            ),
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
    );
  }
}
