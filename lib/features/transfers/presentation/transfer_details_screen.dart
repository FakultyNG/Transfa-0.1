import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/models/bank.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/primary_button.dart';
import 'transfer_state.dart';

class TransferDetailsScreen extends ConsumerStatefulWidget {
  const TransferDetailsScreen({super.key});

  @override
  ConsumerState<TransferDetailsScreen> createState() =>
      _TransferDetailsScreenState();
}

class _TransferDetailsScreenState extends ConsumerState<TransferDetailsScreen> {
  final _name = TextEditingController();
  final _account = TextEditingController();
  final _bank = TextEditingController();
  final _memo = TextEditingController();
  final _swift = TextEditingController();
  final _routing = TextEditingController();
  final _country = TextEditingController(text: 'US');
  Bank? _selectedBank;
  List<Beneficiary> _beneficiaries = const [];
  List<BankSuggestion> _bankSuggestions = const [];
  Timer? _searchDebounce;
  bool _loading = false;

  TxCurrency get _currency => ref.read(transferDraftProvider).currency;
  bool get _isForeign => _currency != TxCurrency.ngn;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(transferDraftProvider);
    _name.text = draft.recipientName ?? '';
    _account.text = draft.recipientAccount ?? '';
    _bank.text = draft.bankName ?? '';
    _memo.text = draft.memo ?? '';
    _swift.text = draft.swiftCode ?? '';
    _routing.text = draft.routingNumber ?? '';
    _country.text =
        draft.recipientCountry ??
        (draft.currency == TxCurrency.cny ? 'China' : 'US');
    if (draft.bankCode != null && draft.bankName != null) {
      _selectedBank = Bank(code: draft.bankCode!, name: draft.bankName!);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _account.dispose();
    _bank.dispose();
    _memo.dispose();
    _swift.dispose();
    _routing.dispose();
    _country.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  String get _beneficiaryType => '${_currency.name}_transfer';

  void _onAccountChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _beneficiaries = const [];
        _bankSuggestions = const [];
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final repository = ref.read(transferRepositoryProvider);
        final beneficiaries = await repository.searchBeneficiaries(
          query: query,
          type: _beneficiaryType,
        );
        final bankSuggestions =
            _currency == TxCurrency.ngn && query.length == 10
            ? await repository.suggestBanks(query)
            : <BankSuggestion>[];
        if (!mounted || _account.text.trim() != query) return;
        setState(() {
          _beneficiaries = beneficiaries;
          _bankSuggestions = bankSuggestions;
        });
      } catch (_) {
        if (!mounted || _account.text.trim() != query) return;
        setState(() {
          _beneficiaries = const [];
          _bankSuggestions = const [];
        });
      }
    });
  }

  void _selectBeneficiary(Beneficiary beneficiary) {
    setState(() {
      _account.text = beneficiary.accountNumber;
      _name.text = beneficiary.accountName ?? beneficiary.displayName;
      _bank.text = beneficiary.bankName;
      if (beneficiary.bankCode != null) {
        _selectedBank = Bank(
          code: beneficiary.bankCode!,
          name: beneficiary.bankName,
        );
      }
      _beneficiaries = const [];
      _bankSuggestions = const [];
    });
  }

  void _selectSuggestion(BankSuggestion suggestion) {
    setState(() {
      _account.text = suggestion.accountNumber;
      _name.text = suggestion.accountName;
      _bank.text = suggestion.bankName;
      _selectedBank = Bank(
        code: suggestion.bankCode,
        name: suggestion.bankName,
      );
      _beneficiaries = const [];
      _bankSuggestions = const [];
    });
  }

  Future<void> _chooseBank() async {
    try {
      final banks = await ref.read(ngnBanksProvider.future);
      if (!mounted) return;
      final selected = await showModalBottomSheet<Bank>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: ListView.builder(
            itemCount: banks.length,
            itemBuilder: (context, index) {
              final bank = banks[index];
              return ListTile(
                title: Text(bank.name),
                subtitle: Text(bank.code),
                onTap: () => Navigator.pop(context, bank),
              );
            },
          ),
        ),
      );
      if (selected == null || !mounted) return;
      setState(() {
        _selectedBank = selected;
        _bank.text = selected.name;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    }
  }

  Future<void> _next() async {
    final draft = ref.read(transferDraftProvider);
    if (draft.amount == null) return;
    setState(() => _loading = true);
    try {
      final repository = ref.read(transferRepositoryProvider);
      late final String recipientName;
      late final TransferQuote quote;

      if (draft.currency == TxCurrency.usd) {
        recipientName = _name.text.trim();
        quote = await repository.quoteUsd(
          amount: draft.amount!,
          recipientCountry: _country.text.trim(),
          paymentReference: _memo.text.trim().isEmpty
              ? 'Supplier payment'
              : _memo.text.trim(),
          bankName: _bank.text.trim(),
          accountNumber: _account.text.trim(),
          accountName: recipientName,
          swiftCode: _swift.text.trim(),
          routingNumber: _routing.text.trim(),
        );
      } else if (draft.currency == TxCurrency.cny) {
        recipientName = _name.text.trim();
        quote = await repository.quoteCny(
          amount: draft.amount!,
          recipientCountry: _country.text.trim(),
          paymentReference: _memo.text.trim().isEmpty
              ? 'Supplier payment'
              : _memo.text.trim(),
          bankName: _bank.text.trim(),
          accountNumber: _account.text.trim(),
          accountName: recipientName,
          swiftCode: _swift.text.trim(),
        );
      } else {
        final bank = _selectedBank;
        if (bank == null) {
          throw StateError('Select the recipient bank.');
        }
        final resolved = await repository.resolveAccount(
          bankCode: bank.code,
          accountNumber: _account.text.trim(),
        );
        recipientName = resolved.accountName;
        quote = await repository.quoteNgn(
          amount: draft.amount!,
          bankCode: bank.code,
          accountNumber: resolved.accountNumber,
          narration: _memo.text.trim().isEmpty
              ? 'TF Transfer'
              : _memo.text.trim(),
        );
      }

      ref.read(transferDraftProvider.notifier).state = draft.copyWith(
        recipientName: recipientName,
        recipientAccount: _account.text.trim(),
        bankName: _bank.text.trim(),
        bankCode: _selectedBank?.code,
        memo: _memo.text.trim(),
        swiftCode: _swift.text.trim(),
        routingNumber: _routing.text.trim(),
        recipientCountry: _country.text.trim(),
        quote: quote,
      );
      if (mounted) context.push(Routes.transferConfirm);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForeign = _isForeign;
    final canContinue =
        _account.text.trim().isNotEmpty &&
        (isForeign
            ? _name.text.trim().isNotEmpty &&
                  _bank.text.trim().isNotEmpty &&
                  _swift.text.trim().isNotEmpty &&
                  _country.text.trim().isNotEmpty
            : _selectedBank != null);

    return AppScaffold(
      appBar: AppBar(title: const Text('Recipient')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Text(
            isForeign
                ? 'Enter the supplier banking details.'
                : 'Enter and verify the recipient account.',
            style: AppTypography.bodyMuted,
          ),
          const SizedBox(height: 24),
          AppInput(
            label: 'Recipient name',
            hint: 'Full legal name',
            controller: _name,
            capitalization: TextCapitalization.words,
            enabled: isForeign,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          AppInput(
            label: 'Account number',
            hint: isForeign
                ? 'Beneficiary account number'
                : '10-digit account number',
            controller: _account,
            keyboardType: TextInputType.number,
            maxLength: isForeign ? null : 10,
            onChanged: _onAccountChanged,
          ),
          if (_beneficiaries.isNotEmpty || _bankSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._beneficiaries.map(
              (beneficiary) => ListTile(
                dense: true,
                leading: const Icon(Icons.history_rounded),
                title: Text(beneficiary.displayName),
                subtitle: Text(
                  '${beneficiary.bankName} · ${beneficiary.accountNumber}',
                ),
                onTap: () => _selectBeneficiary(beneficiary),
              ),
            ),
            ..._bankSuggestions.map(
              (suggestion) => ListTile(
                dense: true,
                leading: const Icon(Icons.account_balance_rounded),
                title: Text(suggestion.accountName),
                subtitle: Text(
                  '${suggestion.bankName} · ${suggestion.confidence.toStringAsFixed(0)}% match',
                ),
                onTap: () => _selectSuggestion(suggestion),
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppInput(
            label: 'Bank',
            hint: isForeign ? 'Beneficiary bank' : 'Choose bank',
            controller: _bank,
            readOnly: !isForeign,
            onTap: isForeign ? null : _chooseBank,
            trailing: isForeign ? null : const Icon(Icons.expand_more_rounded),
            onChanged: (_) => setState(() {}),
          ),
          if (isForeign) ...[
            const SizedBox(height: 16),
            AppInput(
              label: 'SWIFT / BIC',
              hint: 'BOFAUS3N',
              controller: _swift,
              capitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            AppInput(
              label: 'Routing number',
              hint: 'Optional where not required',
              controller: _routing,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            AppInput(
              label: 'Recipient country',
              hint: _currency == TxCurrency.cny ? 'China' : 'US',
              controller: _country,
              capitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 16),
          AppInput(
            label: isForeign ? 'Payment reference' : 'Narration',
            hint: isForeign ? 'Invoice or supplier reference' : 'TF Transfer',
            controller: _memo,
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Continue',
            loading: _loading,
            onPressed: canContinue ? _next : null,
          ),
        ],
      ),
    );
  }
}
