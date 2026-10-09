import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';

class TransactionDetailsScreen extends ConsumerWidget {
  final String id;
  const TransactionDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(transactionRepositoryProvider);
    return AppScaffold(
      appBar: AppBar(title: const Text('Transaction')),
      body: FutureBuilder<AppTransaction?>(
        future: repo.get(id),
        builder: (_, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                'Unable to load this transaction.',
                style: AppTypography.bodyMuted,
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tx = snap.data;
          if (tx == null) {
            return Center(
              child: Text('Not found', style: AppTypography.bodyMuted),
            );
          }
          final isCredit = tx.type == TxType.credit;
          final amountStr = switch (tx.currency) {
            TxCurrency.ngn => AppFormat.ngn(tx.amount),
            TxCurrency.usd => AppFormat.usd(tx.amount),
            TxCurrency.cny => AppFormat.cny(tx.amount),
          };
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: (isCredit ? AppColors.success : AppColors.primary)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCredit
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    size: 44,
                    color: isCredit ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '${isCredit ? '+' : '-'}$amountStr',
                  style: AppTypography.displayMedium,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  AppFormat.dateTime(tx.createdAt),
                  style: AppTypography.bodyMuted,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    _Row(label: 'Status', value: tx.status.name),
                    _Row(label: 'Reference', value: tx.id),
                    _Row(
                      label: isCredit ? 'From' : 'To',
                      value: tx.counterpartyName,
                    ),
                    if (tx.counterpartyAccount != null)
                      _Row(label: 'Account', value: tx.counterpartyAccount!),
                    if (tx.bankName != null)
                      _Row(label: 'Bank / Network', value: tx.bankName!),
                    if ((tx.memo ?? '').isNotEmpty)
                      _Row(label: 'Memo', value: tx.memo!),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Share receipt', onPressed: () {}),
            ],
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodyMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.body,
            ),
          ),
        ],
      ),
    );
  }
}
