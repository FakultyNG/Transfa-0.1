import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/constants/assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/models/bank.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/transfa_modal_header.dart';
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(userFacingError(error))));
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(userFacingError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(transferDraftProvider);
    final isForeign = _isForeign;
    final canContinue =
        _account.text.trim().isNotEmpty &&
        (isForeign
            ? _name.text.trim().isNotEmpty &&
                  _bank.text.trim().isNotEmpty &&
                  _swift.text.trim().isNotEmpty &&
                  _country.text.trim().isNotEmpty
            : _selectedBank != null);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            TransfaModalHeader(onClose: () => context.pop()),
            const SizedBox(height: 34),
            Row(
              children: [
                Text(
                  'To:',
                  style: AppTypography.subheading.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _account,
                    keyboardType: TextInputType.number,
                    maxLength: isForeign ? null : 10,
                    onChanged: _onAccountChanged,
                    style: AppTypography.subheading.copyWith(fontSize: 22),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Account number…',
                      hintStyle: AppTypography.subheading.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 22,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
            if (_name.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 48, bottom: 8),
                child: Text(
                  _name.text.trim(),
                  style: AppTypography.body.copyWith(
                    color: AppColors.success,
                    fontSize: 16,
                  ),
                ),
              ),
            const Divider(color: Color(0xFFE0E0E0)),
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
            InkWell(
              onTap: isForeign ? null : _chooseBank,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(11),
                      child: SvgPicture.asset(
                        Assets.bankBlack,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: isForeign
                          ? TextField(
                              controller: _bank,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: 'Beneficiary bank',
                                border: InputBorder.none,
                              ),
                            )
                          : Text(
                              _selectedBank?.name ?? 'Bank Center',
                              style: AppTypography.subheading.copyWith(
                                color: _selectedBank == null
                                    ? AppColors.textMuted
                                    : Colors.black,
                                fontSize: 22,
                              ),
                            ),
                    ),
                    const Icon(
                      Icons.unfold_more_rounded,
                      color: AppColors.textMuted,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: Color(0xFFE0E0E0)),
            if (isForeign) ...[
              const SizedBox(height: 16),
              _LineInput(controller: _name, hint: 'Recipient legal name'),
              _LineInput(controller: _swift, hint: 'SWIFT / BIC'),
              _LineInput(
                controller: _routing,
                hint: 'Routing number (optional)',
              ),
              _LineInput(controller: _country, hint: 'Recipient country'),
            ],
            const SizedBox(height: 28),
            Text(
              'Send',
              style: AppTypography.subheading.copyWith(
                color: AppColors.textMuted,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_currency == TxCurrency.ngn
                  ? '₦'
                  : _currency == TxCurrency.usd
                  ? '\$'
                  : '¥'}${draft.amount?.toStringAsFixed(2) ?? '0.00'}',
              style: AppTypography.displayLarge.copyWith(
                fontSize: 48,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 28),
            const Divider(color: Color(0xFFE0E0E0)),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _memo,
                    decoration: const InputDecoration(
                      hintText: "What's the money for?",
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Color(0xFFE0E0E0)),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Touch to Continue',
              loading: _loading,
              onPressed: canContinue ? _next : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _LineInput extends StatelessWidget {
  const _LineInput({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: InputDecoration(
      hintText: hint,
      border: const UnderlineInputBorder(),
    ),
  );
}
