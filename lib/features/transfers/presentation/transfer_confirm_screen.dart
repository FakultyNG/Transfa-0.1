import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';
import 'transfer_state.dart';

class TransferConfirmScreen extends ConsumerStatefulWidget {
  const TransferConfirmScreen({super.key});

  @override
  ConsumerState<TransferConfirmScreen> createState() =>
      _TransferConfirmScreenState();
}

class _TransferConfirmScreenState extends ConsumerState<TransferConfirmScreen> {
  bool _loading = false;
  final _passcode = TextEditingController();

  @override
  void dispose() {
    _passcode.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      final draft = ref.read(transferDraftProvider);
      final repo = ref.read(transferRepositoryProvider);
      final tx = await repo.confirm(
        quote: draft.quote!,
        passcode: _passcode.text,
        recipientName: draft.recipientName!,
        recipientAccount: draft.recipientAccount,
        bankName: draft.bankName,
        memo: draft.memo,
      );
      ref.invalidate(walletProvider);
      ref.invalidate(transactionsProvider);
      if (mounted) await _showStatusSheet(tx);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showStatusSheet(AppTransaction tx) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _StatusSheet(tx: tx),
    );
    if (!mounted) return;
    ref.read(transferDraftProvider.notifier).state = const TransferDraft();
    context.go(Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(transferDraftProvider);
    final q = draft.quote;
    if (q == null) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final isUsd = q.currency == TxCurrency.usd;
    final sendingLabel = isUsd
        ? '${AppFormat.usd(q.amount)} USD'
        : AppFormat.ngn(q.amount);
    return AppScaffold(
      appBar: AppBar(title: const Text('Confirm transfer')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Text(
                  'You\'re sending',
                  style: AppTypography.caption.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  sendingLabel,
                  style: AppTypography.displayMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                if (isUsd) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Wallet debit: ${AppFormat.ngn(q.ngnAmount)}',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _Row(label: 'Recipient', value: draft.recipientName ?? '—'),
                _Row(label: 'Account', value: draft.recipientAccount ?? '—'),
                _Row(
                  label: isUsd ? 'Network' : 'Bank',
                  value: draft.bankName ?? '—',
                ),
                if ((draft.memo ?? '').isNotEmpty)
                  _Row(label: 'Memo', value: draft.memo!),
                const Divider(),
                _Row(label: 'Fee', value: AppFormat.ngn(q.fee)),
                if (isUsd)
                  _Row(
                    label: 'FX rate',
                    value: '₦${q.fxRate!.toStringAsFixed(2)} / USD',
                  ),
                _Row(
                  label: 'Total debit',
                  value: AppFormat.ngn(q.total),
                  strong: true,
                ),
              ],
            ),
          ),
          const Spacer(),
          AppInput(
            label: 'Transaction passcode',
            hint: '5 digits',
            controller: _passcode,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            obscure: true,
            maxLength: 5,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Confirm & send',
            loading: _loading,
            onPressed: _passcode.text.length == 5 ? _confirm : null,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool strong;
  const _Row({required this.label, required this.value, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: AppTypography.bodyMuted),
          const Spacer(),
          Text(
            value,
            style: strong ? AppTypography.bodyStrong : AppTypography.body,
          ),
        ],
      ),
    );
  }
}

class _StatusSheet extends StatelessWidget {
  final AppTransaction tx;
  const _StatusSheet({required this.tx});

  @override
  Widget build(BuildContext context) {
    final success = tx.status == TxStatus.success;
    final pending = tx.status == TxStatus.pending;
    final color = success
        ? AppColors.success
        : pending
        ? AppColors.warning
        : AppColors.error;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              success
                  ? Icons.check_rounded
                  : pending
                  ? Icons.schedule_rounded
                  : Icons.close_rounded,
              size: 50,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            success
                ? 'Transfer successful'
                : pending
                ? 'Transfer processing'
                : 'Transfer failed',
            style: AppTypography.headingLarge,
          ),
          const SizedBox(height: 6),
          Text(
            success
                ? 'Your money has been sent successfully.'
                : pending
                ? 'Your transfer was submitted. We will notify you when it completes.'
                : 'Something went wrong. Please try again.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMuted,
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Done', onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
