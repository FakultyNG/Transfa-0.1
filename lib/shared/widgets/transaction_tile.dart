import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction.dart';

class TransactionTile extends StatelessWidget {
  final AppTransaction tx;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.tx, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.type == TxType.credit;
    final amountStr = switch (tx.currency) {
      TxCurrency.ngn => AppFormat.ngn(tx.amount),
      TxCurrency.usd => AppFormat.usd(tx.amount),
      TxCurrency.cny => AppFormat.cny(tx.amount),
    };
    final sign = isCredit ? '+' : '-';
    final amountColor = isCredit ? AppColors.success : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            _CounterpartyAvatar(tx: tx),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.counterpartyName,
                    style: AppTypography.bodyStrong.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tx.memo ?? tx.bankName ?? 'Bank transfer'} • ${AppFormat.dateTime(tx.createdAt)}',
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign$amountStr',
                  style: AppTypography.bodyStrong.copyWith(
                    color: amountColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                _StatusChip(status: tx.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterpartyAvatar extends StatelessWidget {
  const _CounterpartyAvatar({required this.tx});

  final AppTransaction tx;

  @override
  Widget build(BuildContext context) {
    if ((tx.counterpartyProfileImageUrl ?? '').isNotEmpty) {
      return ClipOval(
        child: Image.network(
          tx.counterpartyProfileImageUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initials(),
        ),
      );
    }
    return _initials();
  }

  Widget _initials() {
    const colors = [Color(0xFF075E54), Color(0xFFAD1457), Color(0xFF29B6F6)];
    final words = tx.counterpartyName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? 'TF'
        : words.take(2).map((word) => word[0].toUpperCase()).join();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors[tx.counterpartyName.hashCode.abs() % colors.length],
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTypography.bodyStrong.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TxStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    late String label;
    switch (status) {
      case TxStatus.success:
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        label = 'Successful';
        break;
      case TxStatus.pending:
        bg = AppColors.warning.withValues(alpha: 0.14);
        fg = AppColors.warning;
        label = 'Pending';
        break;
      case TxStatus.failed:
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        label = 'Failed';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.small.copyWith(color: fg, fontSize: 11),
      ),
    );
  }
}
