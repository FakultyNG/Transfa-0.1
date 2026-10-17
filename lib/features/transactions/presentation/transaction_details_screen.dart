import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/repositories.dart';
import '../../transfers/presentation/receipt_screens.dart';

/// Loads live transaction data into the original Transfa receipt UI.
class TransactionDetailsScreen extends ConsumerWidget {
  const TransactionDetailsScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<AppTransaction?>(
      future: ref.watch(transactionRepositoryProvider).get(id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _TransactionLoadState(
            message: 'Unable to load this transaction.',
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final transaction = snapshot.data;
        if (transaction == null) {
          return const _TransactionLoadState(message: 'Transaction not found.');
        }
        return TransferReceiptScreen(
          transaction: transaction,
          recipientName: transaction.counterpartyName,
          accountNumber: transaction.counterpartyAccount ?? '—',
          bankName: transaction.bankName ?? 'Transfa',
          memo: transaction.memo ?? 'Bank transfer',
        );
      },
    );
  }
}

class _TransactionLoadState extends StatelessWidget {
  const _TransactionLoadState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(child: Text(message, style: AppTypography.bodyMuted)),
  );
}
