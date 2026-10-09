import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/transaction.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';
import 'transfer_state.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _amount = TextEditingController();
  TxCurrency _currency = TxCurrency.ngn;

  double? get _parsedAmount =>
      double.tryParse(_amount.text.replaceAll(',', ''));

  void _openCurrencySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text('Choose currency', style: AppTypography.subheading),
            const SizedBox(height: 12),
            _CurrencyRow(
              flag: '🇳🇬',
              code: 'NGN',
              name: 'Nigerian Naira',
              selected: _currency == TxCurrency.ngn,
              onTap: () {
                setState(() => _currency = TxCurrency.ngn);
                Navigator.pop(context);
              },
            ),
            _CurrencyRow(
              flag: '🇨🇳',
              code: 'CNY',
              name: 'Chinese Yuan payout',
              selected: _currency == TxCurrency.cny,
              onTap: () {
                setState(() => _currency = TxCurrency.cny);
                Navigator.pop(context);
              },
            ),
            _CurrencyRow(
              flag: '🇺🇸',
              code: 'USD',
              name: 'US Dollar (stablecoin payout)',
              selected: _currency == TxCurrency.usd,
              onTap: () {
                setState(() => _currency = TxCurrency.usd);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _continue() {
    final amt = _parsedAmount;
    if (amt == null || amt <= 0) return;
    ref.read(transferDraftProvider.notifier).state = ref
        .read(transferDraftProvider)
        .copyWith(currency: _currency, amount: amt);
    context.push(Routes.transferDetails);
  }

  @override
  Widget build(BuildContext context) {
    final symbol = switch (_currency) {
      TxCurrency.ngn => '₦',
      TxCurrency.usd => '\$',
      TxCurrency.cny => '¥',
    };
    final flag = switch (_currency) {
      TxCurrency.ngn => '🇳🇬',
      TxCurrency.usd => '🇺🇸',
      TxCurrency.cny => '🇨🇳',
    };
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Send money'),
        actions: [
          IconButton(
            tooltip: 'Recent recipients',
            onPressed: () => context.push(Routes.beneficiaries),
            icon: const Icon(Icons.people_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Text('How much do you want to send?', style: AppTypography.bodyMuted),
          const SizedBox(height: 20),
          InkWell(
            onTap: _openCurrencySheet,
            borderRadius: BorderRadius.circular(35),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Text(flag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Text(
                    _currency.name.toUpperCase(),
                    style: AppTypography.bodyStrong,
                  ),
                  const Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.textMuted,
                  ),
                  const Spacer(),
                  Text(
                    'Tap to switch',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  symbol,
                  style: AppTypography.displayLarge.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    textAlign: TextAlign.start,
                    style: AppTypography.displayLarge.copyWith(fontSize: 40),
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Continue',
            onPressed: (_parsedAmount ?? 0) > 0 ? _continue : null,
          ),
        ],
      ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  final String flag, code, name;
  final bool selected;
  final VoidCallback onTap;
  const _CurrencyRow({
    required this.flag,
    required this.code,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(code, style: AppTypography.bodyStrong),
                  Text(name, style: AppTypography.caption),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
