import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';

class WalletOverviewScreen extends ConsumerStatefulWidget {
  const WalletOverviewScreen({super.key});

  @override
  ConsumerState<WalletOverviewScreen> createState() =>
      _WalletOverviewScreenState();
}

class _WalletOverviewScreenState extends ConsumerState<WalletOverviewScreen> {
  final _reference = TextEditingController();
  bool _verifying = false;

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  Future<void> _verifyFunding() async {
    setState(() => _verifying = true);
    try {
      final transaction = await ref
          .read(walletRepositoryProvider)
          .verifyFunding(_reference.text.trim());
      ref.invalidate(walletProvider);
      ref.invalidate(walletSummaryProvider);
      ref.invalidate(transactionsProvider);
      if (!mounted) return;
      _reference.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Funding verified: ${AppFormat.ngn(transaction.amount)}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(walletSummaryProvider);
    final dva = ref.watch(dvaProvider);
    return AppScaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletSummaryProvider);
          ref.invalidate(dvaProvider);
          await ref.read(walletSummaryProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            summary.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Text(userFacingError(error), style: AppTypography.bodyMuted),
              data: (item) => Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppFormat.ngn(item.balance),
                      style: AppTypography.displayLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: 'Total inflow',
                          value: AppFormat.ngn(item.totalInflow),
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Metric(
                          label: 'Total outflow',
                          value: AppFormat.ngn(item.totalOutflow),
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Metric(
                    label: 'Pending transactions',
                    value: item.pendingTransactions.toString(),
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Funding account', style: AppTypography.subheading),
            const SizedBox(height: 10),
            dva.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(userFacingError(error)),
              data: (account) => ListTile(
                tileColor: AppColors.surfaceMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(account.accountNumber),
                subtitle: Text('${account.bankName} · ${account.accountName}'),
              ),
            ),
            const SizedBox(height: 28),
            Text('Verify a transfer', style: AppTypography.subheading),
            const SizedBox(height: 8),
            Text(
              'Enter the provider transaction reference if a bank transfer has not appeared yet.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: 14),
            AppInput(
              label: 'Transaction reference',
              hint: 'TRFA_REF_12345',
              controller: _reference,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Verify funding',
              loading: _verifying,
              onPressed: _reference.text.trim().isEmpty ? null : _verifyFunding,
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyStrong.copyWith(color: color),
        ),
      ],
    ),
  );
}
