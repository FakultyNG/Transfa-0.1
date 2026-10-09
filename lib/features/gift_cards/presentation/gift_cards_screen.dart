import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/gift_card.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';

class GiftCardsScreen extends ConsumerWidget {
  const GiftCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        appBar: AppBar(
          title: const Text('Gift cards'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Available'),
              Tab(text: 'My purchases'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_GiftCardCatalogue(), _GiftCardHistory()],
        ),
      ),
    );
  }
}

class _GiftCardCatalogue extends ConsumerWidget {
  const _GiftCardCatalogue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(giftCardsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(giftCardsProvider);
        await ref.read(giftCardsProvider.future);
      },
      child: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorList(error: error),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final product = items[index];
            return ListTile(
              tileColor: AppColors.surfaceMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              leading: const Icon(Icons.card_giftcard_rounded),
              title: Text(product.name),
              subtitle: Text(
                '${product.currency} ${product.minAmount.toStringAsFixed(0)} - ${product.maxAmount.toStringAsFixed(0)}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => _PurchaseSheet(product: product),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GiftCardHistory extends ConsumerWidget {
  const _GiftCardHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchases = ref.watch(giftCardPurchasesProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(giftCardPurchasesProvider);
        await ref.read(giftCardPurchasesProvider.future);
      },
      child: purchases.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorList(error: error),
        data: (items) => items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.card_giftcard_rounded, size: 42),
                  SizedBox(height: 12),
                  Text(
                    'No gift-card purchases yet.',
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    leading: const Icon(Icons.redeem_rounded),
                    title: Text(item.name),
                    subtitle: Text(
                      item.createdAt == null
                          ? item.status.replaceAll('_', ' ')
                          : '${item.status.replaceAll('_', ' ')} · ${AppFormat.dateShort(item.createdAt!)}',
                    ),
                    trailing: Text(
                      '${item.currency} ${item.amount.toStringAsFixed(2)}',
                    ),
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => _PurchaseDetails(id: item.id),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _PurchaseDetails extends ConsumerWidget {
  const _PurchaseDetails({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchase = ref.watch(giftCardPurchaseProvider(id));
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: purchase.when(
        loading: () => const SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => SizedBox(
          height: 240,
          child: Center(child: Text(userFacingError(error))),
        ),
        data: (item) => ListView(
          shrinkWrap: true,
          children: [
            Text(item.name, style: AppTypography.subheading),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Status',
              value: item.status.replaceAll('_', ' '),
            ),
            _DetailRow(
              label: 'Value',
              value: '${item.currency} ${item.amount.toStringAsFixed(2)}',
            ),
            if (item.totalNgnDebit != null)
              _DetailRow(
                label: 'NGN debit',
                value: AppFormat.ngn(item.totalNgnDebit!),
              ),
            if (item.fee != null)
              _DetailRow(label: 'Fee', value: AppFormat.ngn(item.fee!)),
            _DetailRow(label: 'Purchase ID', value: item.id),
            if (item.transactionId != null)
              _DetailRow(label: 'Transaction ID', value: item.transactionId!),
            if (item.createdAt != null)
              _DetailRow(
                label: 'Purchased',
                value: AppFormat.dateTime(item.createdAt!),
              ),
            if (item.expiresAt != null)
              _DetailRow(
                label: 'Expires',
                value: AppFormat.dateShort(item.expiresAt!),
              ),
            if (item.redemptionCode != null ||
                item.redemptionCodeMasked != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Redemption code'),
                subtitle: Text(
                  item.redemptionCode ?? item.redemptionCodeMasked!,
                ),
                trailing: item.redemptionCode == null
                    ? null
                    : IconButton(
                        tooltip: 'Copy code',
                        onPressed: () => Clipboard.setData(
                          ClipboardData(text: item.redemptionCode!),
                        ),
                        icon: const Icon(Icons.copy_rounded),
                      ),
              ),
            if (item.redemptionInstructions != null)
              _DetailRow(
                label: 'Instructions',
                value: item.redemptionInstructions!,
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: AppTypography.bodyMuted),
    subtitle: Text(value),
  );
}

class _ErrorList extends StatelessWidget {
  const _ErrorList({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const SizedBox(height: 120),
      Text(
        userFacingError(error),
        textAlign: TextAlign.center,
        style: AppTypography.bodyMuted,
      ),
    ],
  );
}

class _PurchaseSheet extends ConsumerStatefulWidget {
  const _PurchaseSheet({required this.product});
  final GiftCardProduct product;

  @override
  ConsumerState<_PurchaseSheet> createState() => _PurchaseSheetState();
}

class _PurchaseSheetState extends ConsumerState<_PurchaseSheet> {
  final _amount = TextEditingController();
  final _passcode = TextEditingController();
  GiftCardQuote? _quote;
  bool _loading = false;

  @override
  void dispose() {
    _amount.dispose();
    _passcode.dispose();
    super.dispose();
  }

  Future<void> _getQuote() async {
    final amount = double.tryParse(_amount.text);
    if (amount == null ||
        amount < widget.product.minAmount ||
        amount > widget.product.maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter an amount within the allowed range.'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final quote = await ref
          .read(giftCardRepositoryProvider)
          .quote(product: widget.product, amount: amount);
      if (mounted) setState(() => _quote = quote);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _buy() async {
    if (_quote == null || _passcode.text.length != 5) return;
    setState(() => _loading = true);
    try {
      final purchase = await ref
          .read(giftCardRepositoryProvider)
          .buy(quote: _quote!, passcode: _passcode.text);
      ref.invalidate(walletProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(giftCardPurchasesProvider);
      if (!mounted) return;
      await _showPurchase(purchase);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showPurchase(GiftCardPurchase purchase) async {
    var current = purchase;
    var refreshing = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Purchase submitted'),
          content: Text(
            '${current.name} is ${current.status}. Reference: ${current.id}',
          ),
          actions: [
            TextButton.icon(
              onPressed: refreshing
                  ? null
                  : () async {
                      setDialogState(() => refreshing = true);
                      try {
                        final updated = await ref
                            .read(giftCardRepositoryProvider)
                            .get(current.id);
                        ref.invalidate(giftCardPurchaseProvider(current.id));
                        if (dialogContext.mounted) {
                          setDialogState(() {
                            current = updated;
                            refreshing = false;
                          });
                        }
                      } catch (error) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() => refreshing = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text(userFacingError(error))),
                        );
                      }
                    },
              icon: refreshing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: const Text('Refresh status'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: ListView(
      shrinkWrap: true,
      children: [
        Text(widget.product.name, style: AppTypography.subheading),
        const SizedBox(height: 16),
        AppInput(
          label: 'Amount (${widget.product.currency})',
          hint: widget.product.minAmount.toStringAsFixed(0),
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          enabled: _quote == null,
        ),
        if (_quote != null) ...[
          const SizedBox(height: 16),
          ListTile(
            tileColor: AppColors.surfaceMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text('Total ${AppFormat.ngn(_quote!.totalNgnDebit)}'),
            subtitle: Text('Fee ${AppFormat.ngn(_quote!.fee)}'),
          ),
          const SizedBox(height: 16),
          AppInput(
            label: 'Transaction passcode',
            hint: 'Five digits',
            controller: _passcode,
            obscure: true,
            maxLength: 5,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          label: _quote == null ? 'Get quote' : 'Buy gift card',
          loading: _loading,
          onPressed: _quote == null
              ? _getQuote
              : (_passcode.text.length == 5 ? _buy : null),
        ),
      ],
    ),
  );
}
