import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:transfa/features/pop-ups/businessBanking_popup.dart';
import 'package:transfa/features/pop-ups/personalBanking_popup.dart';
import 'package:transfa/features/pop-ups/transfaAccountPreview_popup.dart';

import '../../../core/constants/assets.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/transaction.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/transfa_logo.dart';
import '../../../features/pop-ups/transfaStatusProgress_popup.dart';
import '../../../features/pop-ups/transfaStatusUnavailable_popup.dart';
import '../../../features/pop-ups/transfaStatus_popup.dart';
import '../../../features/pop-ups/transfaDone_popup.dart';
import '../../../data/repositories/repositories.dart';

/// Universal-Income style receipt — Magic sends ₦2,000,000.
class ReceiptUniversalArgs {
  const ReceiptUniversalArgs({
    required this.transaction,
    required this.recipientName,
  });
  final AppTransaction transaction;
  final String recipientName;
}

class ReceiptUniversalScreen extends ConsumerStatefulWidget {
  const ReceiptUniversalScreen({super.key, this.args});
  final ReceiptUniversalArgs? args;

  @override
  ConsumerState<ReceiptUniversalScreen> createState() =>
      _ReceiptUniversalScreenState();
}

class _ReceiptUniversalScreenState
    extends ConsumerState<ReceiptUniversalScreen> {
  bool _openedShare = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.args != null && !_openedShare) {
      _openedShare = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final tx = widget.args!.transaction;
        await SharePlus.instance.share(
          ShareParams(
            text:
                'Transfa receipt\n${AppFormat.ngn(tx.amount)}\n${widget.args!.recipientName}\nReference: ${tx.reference ?? tx.id}',
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.args?.transaction;
    return _UniversalReceiptPage(
      amount: tx == null ? '₦2,000,000' : AppFormat.ngn(tx.amount),
      subtitle: tx == null
          ? ''
          : (tx.memo?.isNotEmpty == true ? tx.memo! : 'Transfer completed'),
      recipientName: widget.args?.recipientName ?? 'Magic',
      recipientAsset: Assets.magic,
    );
  }
}

/// Naira Received share card — Janelle sends ₦250,000 in. Same layout as
/// the Universal receipt; only the amount, subtitle, and recipient change.
class ReceiptUniversalReceivedScreen extends ConsumerWidget {
  const ReceiptUniversalReceivedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _UniversalReceiptPage(
      amount: '₦250,000',
      subtitle: '“April Salary” received from Janelle',
      recipientName: 'Janelle',
      recipientAsset: Assets.avatarJanelle,
    );
  }
}

/// Processing share card — ₦250,000 pending; amount renders in brand
/// orange to signal the funds are waiting.
class ReceiptUniversalProcessingScreen extends ConsumerWidget {
  const ReceiptUniversalProcessingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _UniversalReceiptPage(
      amount: '₦250,000',
      amountColor: Color(0xFFFF9F0A),
      subtitle: '“April Salary” waiting for you',
      recipientName: 'Janelle',
      recipientAsset: Assets.avatarJanelle,
    );
  }
}

/// Shared "Save to Photos" receipt scaffold. Driven by parameters so the
/// sent / received / processing variants can swap amount, amount color,
/// subtitle, and recipient pill without duplicating the glass card,
/// Time/Day stripe, promo footer, or bottom action bar.
class _UniversalReceiptPage extends StatelessWidget {
  final String amount;
  final Color amountColor;
  final String subtitle;
  final String recipientName;
  final String recipientAsset;

  const _UniversalReceiptPage({
    required this.amount,
    this.amountColor = Colors.black,
    required this.subtitle,
    required this.recipientName,
    required this.recipientAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: GlassCard(
                    padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
                    radius: 36,
                    child: Column(
                      children: [
                        _hPad(const TransfaMark(size: 38)),
                        const SizedBox(height: 6),
                        _hPad(
                          Text(
                            'Transfa Receipt',
                            style: AppTypography.bodyStrong.copyWith(
                              fontSize: 17,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _hPad(
                          Text(
                            amount,
                            style: AppTypography.displayLarge.copyWith(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              color: amountColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _hPad(
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _hPad(
                          _UniversalRecipientPill(
                            name: recipientName,
                            assetImage: recipientAsset,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(36),
                              bottomRight: Radius.circular(36),
                            ),
                          ),
                          child: Column(
                            children: [
                              _MetaRow(
                                icon: _PinkClockIcon(),
                                label: 'Time',
                                value: '11:44:09 AM',
                              ),
                              const Divider(
                                color: Color(0xFFEEEEEE),
                                height: 1,
                              ),
                              _MetaRow(
                                icon: const _DayBadge(),
                                label: 'Day',
                                value: 'Sunday, March 10',
                              ),
                              const Divider(
                                color: Color(0xFFEEEEEE),
                                height: 1,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A1A1A),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: const TransfaMark(
                                        size: 26,
                                        white: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Send Dollars to friends, family,\nand anyone worldwide today.\nTransfa AI is coming soon ❤️💛',
                                      style: AppTypography.body.copyWith(
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Designed by Magic in Ohafia.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _ReceiptIconButton(onTap: () {}),
                  const Spacer(),
                  _SavePill(onTap: () => context.go(Routes.dashboard)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status-style receipt — Magic Payma sends ₦2,000,000 successfully.
class ReceiptStatusScreen extends ConsumerWidget {
  const ReceiptStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shareTransaction = AppTransaction(
      id: 'receipt-status',
      type: TxType.debit,
      status: TxStatus.success,
      currency: TxCurrency.ngn,
      amount: 2000000,
      counterpartyName: 'Magic Payma',
      memo: 'Hi handsome. What\'s up?',
      reference: 'receipt-status',
      createdAt: DateTime.now(),
    );
    return _ReceiptPage(
      amount: '₦2,000,000',
      subtitle: '',
      recipient: const _ReceiptRecipient(
        name: 'Magic Payma',
        assetImage: Assets.magic,
      ),
      memo: 'Hi handsome. What\'s up?',
      status: _ReceiptStatus.done,
      transactionFee: '₦1,000 Fee',
      total: '₦2,026,000',
      supportStyle: _ReceiptSupportStyle.row,
      showShare: true,
      onShare: () => context.push(
        Routes.receiptUniversal,
        extra: ReceiptUniversalArgs(
          transaction: shareTransaction,
          recipientName: 'Magic Payma',
        ),
      ),
      bankName: 'GTBank',
      accountNumber: '0123456789',
    );
  }
}

/// Unable-to-Send variant — payment failed; no Share, support is the
/// blue mini-tile, status is the orange "Unable to Send" badge.
class ReceiptUnableScreen extends ConsumerWidget {
  const ReceiptUnableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ReceiptPage(
      amount: '₦36,000',
      subtitle: '“April Salary” could not be sent',
      recipient: const _ReceiptRecipient(
        name: 'Obi Amadioha',
        avatarColor: Color(0xFFFF9F0A),
      ),
      memo: 'April Salary',
      status: _ReceiptStatus.unable,
      transactionFee: '₦5 Fee',
      total: '₦36,005',
      supportStyle: _ReceiptSupportStyle.tile,
      showShare: false,
      bankName: 'Access Bank',
      accountNumber: '9876543210',
    );
  }
}

/// In-Review variant — incoming Naira is held pending KYC. The Status
/// summary is replaced by a Support Memo card with a countdown timer and
/// two action pills (Add BVN / Add Address) that move the user along the
/// flow. Amount renders in orange to flag the pending state.
class ReceiptInReviewScreen extends ConsumerStatefulWidget {
  const ReceiptInReviewScreen({super.key, this.transaction});
  final AppTransaction? transaction;

  @override
  ConsumerState<ReceiptInReviewScreen> createState() =>
      _ReceiptInReviewScreenState();
}

class _ReceiptInReviewScreenState extends ConsumerState<ReceiptInReviewScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get countdown {
    final end =
        widget.transaction?.holdExpiresAt ??
        DateTime.now().add(const Duration(hours: 24));
    final left = end.difference(DateTime.now());
    final seconds = left.isNegative ? 0 : left.inSeconds;
    return '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${((seconds % 3600) ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final memo = tx?.memo?.trim().isNotEmpty == true
        ? tx!.memo!.trim()
        : 'Bank transfer';
    final isPrime = tx?.requiredTier?.toLowerCase() == 'prime';
    final details =
        'Amount: ${AppFormat.ngn(tx?.amount ?? 250000)}; Sender: ${tx?.counterpartyName ?? 'Janelle Hickinson'}; Reference: ${tx?.reference ?? tx?.id ?? 'pending'}; Message: $memo';
    return _ReceiptPage(
      amount: AppFormat.ngn(tx?.amount ?? 250000),
      amountColor: const Color(0xFFFF9F0A),
      subtitle: '“$memo” waiting for you',
      recipient: _ReceiptRecipient(
        name: tx?.counterpartyName ?? 'Janelle Hickinson',
        assetImage: tx == null ? Assets.avatarJanelle : null,
        networkImage: tx?.counterpartyProfileImageUrl,
      ),
      memo: memo,
      status: _ReceiptStatus.processing,
      transactionFee: '—',
      total: '—',
      supportStyle: _ReceiptSupportStyle.tile,
      showShare: true,
      onShare: tx == null
          ? null
          : () => context.push(
              Routes.receiptUniversal,
              extra: ReceiptUniversalArgs(
                transaction: tx,
                recipientName: tx.counterpartyName,
              ),
            ),
      showPaidWith: false,
      supportMemo: _SupportMemoData(
        title: 'Support Memo',
        timer: countdown,
        body: 'This amount is beyond your money limits, add your NIN or use the get support button to complete this transaction and raise your money limits.',
        actions: [
          _ReceiptAction(
            label: isPrime ? 'NIN verified' : 'Add NIN',
            onTap: isPrime ? null : () => context.push(Routes.addNin),
          ),
          _ReceiptAction(
            label: 'Get support',
            onTap: () => context.push(
              Routes.supportChat,
              extra:
                  'I need help upgrading my money limits to receive this transaction detailed below : $details',
            ),
          ),
        ],
      ),
      bankName: tx?.bankName ?? 'GTBank',
      accountNumber: tx?.counterpartyAccount ?? '—',
      createdAt: tx?.createdAt,
      transactionReference: tx?.reference ?? tx?.id,
    );
  }
}

/// Received variant — Janelle sends ₦250,000 in; processing pending.
class ReceiptReceivedScreen extends ConsumerWidget {
  const ReceiptReceivedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ReceiptPage(
      amount: '₦250,000',
      subtitle: '“April Salary” received from Janelle',
      recipient: const _ReceiptRecipient(
        name: 'Janelle Hickinson',
        assetImage: Assets.avatarJanelle,
      ),
      memo: 'April Salary',
      status: _ReceiptStatus.processing,
      transactionFee: '₦25 Fee',
      total: '₦250,025',
      supportStyle: _ReceiptSupportStyle.tile,
      showShare: true,
      onShare: () => context.push(Routes.receiptUniversal),
      bankName: 'GTBank',
      accountNumber: '0123456789',
    );
  }
}

/// Company cashout variant — Uptown Stores pays out ₦5,000. Recipient
/// renders as a blue business tile, the status summary collapses to just
/// Status (Done) + Total (no Transaction fee row).
class ReceiptReceivedCompanyScreen extends ConsumerWidget {
  const ReceiptReceivedCompanyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ReceiptPage(
      amount: '₦5,000',
      subtitle: '“Cashout” received from Uptown',
      recipient: const _ReceiptRecipient(
        name: 'Uptown Stores',
        businessIcon: true,
      ),
      memo: 'Cashout',
      status: _ReceiptStatus.done,
      total: '₦5,000',
      supportStyle: _ReceiptSupportStyle.tile,
      showShare: true,
      onShare: () => context.push(Routes.receiptUniversal),
      bankName: 'GTBank',
      accountNumber: '0123456789',
    );
  }
}

/// Live transfer receipt using the values returned by the transfer API.
class TransferReceiptScreen extends ConsumerStatefulWidget {
  const TransferReceiptScreen({
    super.key,
    required this.transaction,
    required this.recipientName,
    required this.accountNumber,
    required this.bankName,
    required this.memo,
  });

  final AppTransaction transaction;
  final String recipientName;
  final String accountNumber;
  final String bankName;
  final String memo;

  @override
  ConsumerState<TransferReceiptScreen> createState() =>
      _TransferReceiptScreenState();
}

class _TransferReceiptScreenState extends ConsumerState<TransferReceiptScreen> {
  Timer? _statusTimer;
  late AppTransaction _transaction;
  bool _polling = false;
  bool _shownCompletedPopup = false;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
    if (_transaction.status == TxStatus.pending) {
      _statusTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _refreshStatus(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStatus());
    }
  }

  Future<void> _refreshStatus() async {
    if (_polling || !mounted || _transaction.status != TxStatus.pending) return;
    _polling = true;
    try {
      final latest = await ref
          .read(transactionRepositoryProvider)
          .get(_transaction.id);
      if (!mounted || latest == null) return;
      final completedNow =
          _transaction.status == TxStatus.pending &&
          latest.status == TxStatus.success;
      setState(() => _transaction = latest);
      if (latest.status != TxStatus.pending) {
        _statusTimer?.cancel();
        ref.invalidate(transactionsProvider);
      }
      if (completedNow && !_shownCompletedPopup) {
        _shownCompletedPopup = true;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.6),
          builder: (_) => TransfaDonePopup(
            userName: widget.recipientName,
            userImageUrl: latest.counterpartyProfileImageUrl,
            navigateToReceipt: false,
          ),
        );
      }
    } catch (_) {
      // Keep showing the last confirmed state and retry on the next interval.
    } finally {
      _polling = false;
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transaction = _transaction;
    final received = transaction.type == TxType.credit;
    final status = switch (transaction.status) {
      TxStatus.success => _ReceiptStatus.done,
      TxStatus.pending => _ReceiptStatus.processing,
      TxStatus.failed => _ReceiptStatus.unable,
    };
    final total = transaction.totalDebit > 0
        ? transaction.totalDebit
        : transaction.amount + transaction.fee;
    return _ReceiptPage(
      amount: AppFormat.ngn(transaction.amount),
      amountColor: transaction.status == TxStatus.pending
          ? const Color(0xFFFF9F0A)
          : Colors.black,
      subtitle: transaction.status == TxStatus.failed
          ? 'Transfer could not be sent'
          : transaction.status == TxStatus.pending
          ? 'Transfer is processing'
          : received
          ? 'Received from ${widget.recipientName}'
          : 'Sent to ${widget.recipientName}',
      recipient: _ReceiptRecipient(
        name: widget.recipientName,
        avatarColor: const Color(0xFF16A34A),
        networkImage: transaction.counterpartyProfileImageUrl,
      ),
      memo: widget.memo.isEmpty ? 'Naira transfer' : widget.memo,
      status: status,
      transactionFee: '${AppFormat.ngn(transaction.fee)} Fee',
      total: AppFormat.ngn(total),
      supportStyle: _ReceiptSupportStyle.row,
      showShare: transaction.status == TxStatus.success,
      onShare: transaction.status == TxStatus.success
          ? () => context.push(
              Routes.receiptUniversal,
              extra: ReceiptUniversalArgs(
                transaction: transaction,
                recipientName: widget.recipientName,
              ),
            )
          : null,
      bankName: widget.bankName,
      accountNumber: widget.accountNumber,
      createdAt: transaction.createdAt,
      transactionReference: transaction.reference ?? transaction.id,
      supportMessage:
          'I need help with transaction ${transaction.reference ?? transaction.id}: '
          '${received ? 'received from' : 'sent to'} ${widget.recipientName}, '
          '${AppFormat.ngn(transaction.amount)}, status ${transaction.status.name}.',
    );
  }
}

// =============================================================
//  Shared receipt page scaffold + sub-widgets
// =============================================================

enum _ReceiptStatus { done, processing, unable }

enum _ReceiptSupportStyle { row, tile }

class _ReceiptRecipient {
  final String name;
  final String? assetImage;
  final Color? avatarColor;
  final bool businessIcon;
  final String? networkImage;

  const _ReceiptRecipient({
    required this.name,
    this.assetImage,
    this.avatarColor,
    this.businessIcon = false,
    this.networkImage,
  });
}

/// Composes the full Transfa receipt page: header, amount block, recipient
/// pill, memo bubble, status summary, edge-to-edge detail stripe, and the
/// support footer + floating action bar. All variations (sent / received /
/// unable) are driven by parameters here.
class _ReceiptPage extends StatelessWidget {
  final String amount;
  final Color amountColor;
  final String subtitle;
  final _ReceiptRecipient recipient;
  final String memo;
  final _ReceiptStatus status;
  final String? transactionFee;
  final String total;
  final _ReceiptSupportStyle supportStyle;
  final bool showShare;
  final VoidCallback? onShare;
  final _SupportMemoData? supportMemo;
  final bool showPaidWith;
  final String? bankName;
  final String? accountNumber;
  final DateTime? createdAt;
  final String? transactionReference;
  final String? supportMessage;

  const _ReceiptPage({
    required this.amount,
    this.amountColor = Colors.black,
    required this.subtitle,
    required this.recipient,
    required this.memo,
    required this.status,
    this.transactionFee,
    required this.total,
    required this.supportStyle,
    required this.showShare,
    this.onShare,
    this.supportMemo,
    this.showPaidWith = true,
    this.bankName,
    this.accountNumber,
    this.createdAt,
    this.transactionReference,
    this.supportMessage,
  });

  void _showProgressPopup(BuildContext context) {
    final amountValue =
        double.tryParse(amount.replaceAll(RegExp(r'[₦$,]'), '')) ?? 0;
    final bank = bankName ?? 'Unknown Bank';
    final account = accountNumber ?? 'N/A';

    switch (status) {
      case _ReceiptStatus.done:
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withValues(alpha: 0.5),
          builder: (context) => TransfaStatusPopup(
            businessName: recipient.name,
            amount: amountValue,
            description: memo,
            bankName: bank,
            accountNumber: account,
            image: recipient.assetImage ?? '',
          ),
        );
        break;
      case _ReceiptStatus.processing:
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withValues(alpha: 0.5),
          builder: (context) => TransfaStatusProgressPopup(
            accountName: recipient.name,
            amount: amountValue,
            description: memo,
            bankName: bank,
            accountNumber: account,
            image: recipient.assetImage ?? '',
          ),
        );
        break;
      case _ReceiptStatus.unable:
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withValues(alpha: 0.5),
          builder: (context) => TransfaStatusUnavailablePopup(
            accountName: recipient.name,
            amount: amountValue,
            description: memo,
            bankName: bank,
            accountNumber: account,
            image: recipient.assetImage ?? '',
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inReview = supportMemo != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 140),
              children: [
                _hPad(
                  Column(
                    children: [
                      const TransfaMark(size: 38),
                      const SizedBox(height: 6),
                      Text(
                        'Transfa Receipt',
                        style: AppTypography.bodyStrong.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _hPad(
                  Center(
                    child: Text(
                      amount,
                      style: AppTypography.displayLarge.copyWith(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: amountColor,
                      ),
                    ),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _hPad(
                    Center(
                      child: Text(
                        subtitle,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => {
                    if (bankName == "Transfa")
                      {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierColor: Colors.black.withValues(alpha: 0.5),
                          builder: (context) => PersonalBankingPopup(
                            recipientName: recipient.name,
                            recipientImageUrl:
                                recipient.assetImage ?? Assets.magic,
                            accountNumber: accountNumber ?? 'N/A',
                            bankName: bankName ?? 'Unknown Bank',
                            // bankLogoAsset: widget.bankLogoAsset,
                            onSaveToTransfa: () {
                              // Handle Save to Transfa action
                            },
                            onTransfaCashDrop: () {
                              // Handle Transfa CashDrop action
                            },
                          ),
                        ),
                      }
                    else if (recipient.businessIcon == true)
                      {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierColor: Colors.black.withValues(alpha: 0.5),
                          builder: (context) => BusinessBankingPopup(
                            businessName: recipient.name,
                            // businessImageUrl: recipient.assetImage ?? Assets.magic,
                            onSaveToTransfa: () {
                              // Handle Save to Transfa action
                            },
                            onTransfaCashDrop: () {
                              // Handle Transfa CashDrop action
                            },
                          ),
                        ),
                      }
                    else
                      {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierColor: Colors.black.withValues(alpha: 0.5),
                          builder: (context) => TransfaAccountPreviewPopup(
                            userName: recipient.name,
                            userImageUrl: recipient.assetImage ?? '',
                            onSaveToTransfa: () {
                              // Handle Save to Transfa action
                            },
                            onTransfaCashDrop: () {
                              // Handle Transfa CashDrop action
                            },
                          ),
                        ),
                      },
                  },
                  child: _hPad(_RecipientPill(recipient: recipient)),
                ),

                if (inReview) ...[
                  const SizedBox(height: 18),
                  _hPad(_SupportMemoCard(data: supportMemo!)),
                  const SizedBox(height: 14),
                  _hPad(_ActionPillRow(actions: supportMemo!.actions)),
                ] else ...[
                  const SizedBox(height: 20),
                  _hPad(_MemoBubble(text: memo)),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _showProgressPopup(context),
                    child: _hPad(
                      _StatusSummaryCard(
                        status: status,
                        transactionFee: transactionFee,
                        total: total,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 50),
                _DetailStripe(
                  showPaidWith: showPaidWith,
                  createdAt: createdAt,
                  transactionReference: transactionReference,
                ),
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: () =>
                      context.push(Routes.supportChat, extra: supportMessage),
                  child: _hPad(
                    supportStyle == _ReceiptSupportStyle.row
                        ? const _GetSupportCard()
                        : const _SupportTile(),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: Row(
                children: [
                  _SaveIconButton(
                    onTap: () {
                      context.push(Routes.transfaAi);
                    },
                  ),
                  const Spacer(),
                  if (showShare) _SharePill(onTap: onShare ?? () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar + name pill — the white rounded "who" row. Handles photo
/// avatars (assetImage) and solid-color silhouette avatars (avatarColor).
class _RecipientPill extends StatelessWidget {
  final _ReceiptRecipient recipient;
  const _RecipientPill({required this.recipient});

  @override
  Widget build(BuildContext context) {
    final Widget avatar;
    if (recipient.businessIcon) {
      avatar = Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3D8BFF), Color(0xFF1F5FE0)],
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.business_rounded,
          color: Colors.white,
          size: 28,
        ),
      );
    } else if (recipient.networkImage != null) {
      avatar = CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: NetworkImage(recipient.networkImage!),
      );
    } else if (recipient.assetImage != null) {
      avatar = CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: AssetImage(recipient.assetImage!),
      );
    } else {
      avatar = Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: recipient.avatarColor ?? const Color(0xFFD9D9D9),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(Assets.contacts, fit: BoxFit.cover, height: 46),
      );
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 243, 243, 243),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              recipient.name,
              style: AppTypography.subheading.copyWith(fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }
}

/// White memo pill with the green Union chat-bubble glyph on the left.
class _MemoBubble extends StatelessWidget {
  final String text;
  const _MemoBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: SvgPicture.asset(Assets.union, fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: AppTypography.subheading.copyWith(fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status / Transaction / Total summary card. Status row
/// switches between Done (green check), Processing (orange clock), and
/// Unable to Send (orange info-circle).
class _StatusSummaryCard extends StatelessWidget {
  final _ReceiptStatus status;
  final String? transactionFee;
  final String total;

  const _StatusSummaryCard({
    required this.status,
    this.transactionFee,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Status',
            value: _StatusBadge(status: status),
          ),
          if (transactionFee != null) ...[
            const Divider(color: Color(0xFFEEEEEE), height: 1),
            _SummaryRow(
              label: 'Transaction',
              value: Text(
                transactionFee!,
                style: AppTypography.subheading.copyWith(fontSize: 17),
              ),
            ),
          ],
          const Divider(color: Color(0xFFEEEEEE), height: 1),
          _SummaryRow(
            label: 'Total',
            labelBold: true,
            value: Text(
              total,
              style: AppTypography.subheading.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Composite status badge — icon + label, color-coded per state.
class _StatusBadge extends StatelessWidget {
  final _ReceiptStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      _ReceiptStatus.done => (
        const _DoneBadge(),
        'Done',
        const Color(0xFF07B826),
      ),
      _ReceiptStatus.processing => (
        const _ProcessingBadge(),
        'Processing',
        const Color(0xFFFF9F0A),
      ),
      _ReceiptStatus.unable => (
        const _UnableBadge(),
        'Unable to Send',
        const Color(0xFFFF9F0A),
      ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.subheading.copyWith(fontSize: 17, color: color),
        ),
      ],
    );
  }
}

/// Orange clock badge — Processing state.
class _ProcessingBadge extends StatelessWidget {
  const _ProcessingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0xFFFF9F0A),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.access_time_filled_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

/// Orange ring with "i" inside — Unable to Send state.
class _UnableBadge extends StatelessWidget {
  const _UnableBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFF9F0A), width: 2),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.priority_high_rounded,
        color: Color(0xFFFF9F0A),
        size: 16,
      ),
    );
  }
}

/// Edge-to-edge white detail stripe with Time / Day / Transaction ID /
/// Paid with rows. Shared by every receipt variant.
class _DetailStripe extends StatelessWidget {
  final bool showPaidWith;
  final DateTime? createdAt;
  final String? transactionReference;
  const _DetailStripe({
    this.showPaidWith = true,
    this.createdAt,
    this.transactionReference,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _DetailRow(
            icon: _PinkClockIcon(),
            label: 'Time',
            value: createdAt == null
                ? '—'
                : DateFormat('h:mm:ss a').format(createdAt!.toLocal()),
          ),
          const Divider(color: Color(0xFFE6E6E8), height: 1),
          _DetailRow(
            icon: const _DayBadge(),
            label: 'Day',
            value: createdAt == null
                ? '—'
                : DateFormat('EEEE, MMMM d').format(createdAt!.toLocal()),
          ),
          const Divider(color: Color(0xFFE6E6E8), height: 1),
          _DetailRow(
            icon: const _TransactionIdIcon(),
            label: 'Transaction ID',
            value: transactionReference ?? '—',
          ),
          if (showPaidWith) ...[
            const Divider(color: Color(0xFFE6E6E8), height: 1),
            _DetailRow(
              icon: const _PaidWithIcon(),
              label: 'Paid with',
              value: 'Transfa Balance',
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================
//  In-Review variant: Support Memo card + action pills
// =============================================================

class _ReceiptAction {
  final String label;
  final VoidCallback? onTap;
  const _ReceiptAction({required this.label, required this.onTap});
}

class _SupportMemoData {
  final String title;
  final String timer;
  final String body;
  final List<_ReceiptAction> actions;
  const _SupportMemoData({
    required this.title,
    required this.timer,
    required this.body,
    required this.actions,
  });
}

/// White rounded card holding the Support Memo: blue Transfa tile + title
/// + orange countdown timer on the first row, paragraph body below.
class _SupportMemoCard extends StatelessWidget {
  final _SupportMemoData data;
  const _SupportMemoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3D8BFF), Color(0xFF1F5FE0)],
                  ),
                ),
                alignment: Alignment.center,
                child: const TransfaMark(size: 18, white: true),
              ),
              const SizedBox(width: 12),
              Text(
                data.title,
                style: AppTypography.subheading.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                data.timer,
                style: AppTypography.subheading.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF9F0A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data.body,
            style: AppTypography.body.copyWith(
              fontSize: 17,
              height: 1.35,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Side-by-side white action pills shown under the Support Memo card.
class _ActionPillRow extends StatelessWidget {
  final List<_ReceiptAction> actions;
  const _ActionPillRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(child: _ActionPill(action: actions[i])),
        ],
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  final _ReceiptAction action;
  const _ActionPill({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: action.onTap == null ? const Color(0xFFE9E9EA) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          action.label,
          style: AppTypography.subheading.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: action.onTap == null ? AppColors.textMuted : null,
          ),
        ),
      ),
    );
  }
}

/// Wraps a child in the receipt's standard 20px horizontal gutter so the
/// edge-to-edge white detail stripe can stay flush to the screen edges
/// while every other child keeps its normal page padding.
Widget _hPad(Widget child) =>
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child);

// ---------- shared bits ----------

/// Shareable "Save to Photos" recipient pill used by all Universal-style
/// receipts (sent / received / processing). Same light-grey rounded pill
/// silhouette with a circular avatar and a short first-name label.
class _UniversalRecipientPill extends StatelessWidget {
  final String name;
  final String assetImage;
  const _UniversalRecipientPill({required this.name, required this.assetImage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 247, 247, 247),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: AssetImage(assetImage),
          ),
          const SizedBox(width: 14),
          Text(name, style: AppTypography.subheading.copyWith(fontSize: 22)),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTypography.subheading.copyWith(
              color: AppColors.textMuted,
              fontSize: 17,
            ),
          ),
          const Spacer(),
          Text(value, style: AppTypography.subheading.copyWith(fontSize: 17)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final bool labelBold;
  final Widget value;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.labelBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.subheading.copyWith(
              fontSize: 17,
              fontWeight: labelBold ? FontWeight.w700 : FontWeight.w400,
              color: labelBold ? Colors.black : AppColors.textMuted,
            ),
          ),
          const Spacer(),
          value,
        ],
      ),
    );
  }
}

class _PinkClockIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      alignment: Alignment.center,
      child: SizedBox(
        width: 18,
        height: 18,
        child: SvgPicture.asset(Assets.time, fit: BoxFit.contain),
      ),
    );
  }
}

/// Detail row used inside the white "details" card on the receipt —
/// leading icon glyph + label + right-aligned value, with a divider
/// between entries.
class _DetailRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTypography.subheading.copyWith(
              color: AppColors.textMuted,
              fontSize: 17,
            ),
          ),
          const Spacer(),
          Text(value, style: AppTypography.subheading.copyWith(fontSize: 17)),
        ],
      ),
    );
  }
}

/// Tiny red rounded calendar badge — leading widget of the floating bar.
/// Small pink mini-calendar badge — used as the leading icon on the "Day"
/// detail row (~32px circle with "Fri" + "10" in brand-red).
class _DayBadge extends StatelessWidget {
  const _DayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color.fromARGB(66, 255, 224, 230),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Fri',
            style: AppTypography.caption.copyWith(
              color: const Color(0xFFFF375F),
              fontWeight: FontWeight.w700,
              fontSize: 7,
              height: 1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '10',
            style: AppTypography.subheading.copyWith(
              color: const Color(0xFF000000),
              fontWeight: FontWeight.w800,
              fontSize: 13,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// White circular "Save to Photos" button — bottom-left of the floating
/// bar. Renders the brand Today.svg calendar glyph (matches the original
/// design before the day-badge swap).
class _SaveIconButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SaveIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: 26,
          height: 26,
          child: SvgPicture.asset(Assets.today, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Brand "Transaction ID" badge — Transaction ID.svg is the full glyph
/// (pink circle background + red gradient lines) so it renders directly.
class _TransactionIdIcon extends StatelessWidget {
  const _TransactionIdIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: SvgPicture.asset(Assets.transactionId, fit: BoxFit.contain),
    );
  }
}

/// Small dark circular badge with the white Transfa cross — leading icon
/// for the "Paid with" row.
class _PaidWithIcon extends StatelessWidget {
  const _PaidWithIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const TransfaMark(size: 16, white: true),
    );
  }
}

/// Footer card on the receipt — purple gradient app-icon tile + "Get
/// Support" label + a small chevron on the right.
/// Vertical Support tile — blue rounded square with the Transfa cross and
/// a "Support" label underneath. Used by the unable / received variants
/// where the support entry point is rendered as a compact app-icon tile.
class _SupportTile extends StatelessWidget {
  const _SupportTile();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3D8BFF), Color(0xFF1F5FE0)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F5FE0).withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const TransfaMark(size: 30, white: true),
          ),
          const SizedBox(height: 8),
          Text(
            'Support',
            style: AppTypography.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GetSupportCard extends StatelessWidget {
  const _GetSupportCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9B6CFB), Color(0xFF6B3CD9)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B3CD9).withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const TransfaMark(size: 22, white: true),
          ),
          const SizedBox(width: 14),
          Text(
            'Get Support',
            style: AppTypography.subheading.copyWith(fontSize: 22),
          ),
          const Spacer(),
          const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFFBDBDBD),
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _DoneBadge extends StatelessWidget {
  const _DoneBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
    );
  }
}

/// Small frosted-glass square button at the bottom-left of the Naira
/// receipt — shows a notepad/receipt glyph, hinting at the saved record.
class _ReceiptIconButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ReceiptIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: 22,
          height: 26,
          child: SvgPicture.asset(Assets.download, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// "Save to Photos" frosted-glass action pill on the right of the bottom
/// row — same glass-on-page treatment as the other floating actions.
class _SavePill extends StatelessWidget {
  final VoidCallback onTap;
  const _SavePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'Save to Photos',
          style: AppTypography.subheading.copyWith(fontSize: 17),
        ),
      ),
    );
  }
}

class _SharePill extends StatelessWidget {
  final VoidCallback onTap;
  const _SharePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: SvgPicture.asset(Assets.share, fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            Text(
              'Share',
              style: AppTypography.subheading.copyWith(
                fontSize: 17,
                color: const Color(0xFFFF375F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
