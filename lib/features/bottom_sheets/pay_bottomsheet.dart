import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/assets.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock_api/currency.dart';
import '../../../shared/widgets/transfa_logo.dart';
import '../../../data/models/bank.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/repositories.dart';
import '../../../core/utils/error_messages.dart';
import '../transfers/presentation/transfer_state.dart';
import '../transfers/presentation/choose_bank_screen.dart';
import '../transfers/presentation/recipient_picker_screen.dart';
import '../pop-ups/multiple_banks_popup.dart';
import '../../shared/widgets/bank_logo.dart';
import 'singleAccountSheet.dart';

// ============================================================
// PAY SHEET BOTTOM SHEET
// ============================================================
//
// The "To:" field no longer pushes for a result and fills itself in —
// it opens the recipient picker, and picking a recipient there jumps
// straight into SingleAccountSheet / MultipleAccountsSheet, closing
// this sheet along the way. Everything else here (Bank Center field,
// Summary, Touch to Confirm) is restored as a standalone fallback UI
// and is untouched by that flow change.

class PaySheet extends ConsumerStatefulWidget {
  final String amount;
  final AmountCurrency currency;
  final String memo;
  final Function(String) onMemoChanged;

  const PaySheet({
    super.key,
    required this.amount,
    required this.currency,
    required this.memo,
    required this.onMemoChanged,
  });

  @override
  ConsumerState<PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends ConsumerState<PaySheet> {
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();

  // Selected recipient data - updated from navigation
  String _selectedAccountNumber = '';
  String _selectedBank = '';
  final String _selectedBankLogo = '';
  final Color? _selectedBankGradient1 = null;
  final Color? _selectedBankGradient2 = null;
  String _selectedRecipientName = '';
  String? _selectedRecipientImage;

  Bank? _selectedBankModel;
  List<BankSuggestion> _suggestions = const [];
  TransferQuote? _quote;
  bool _loading = false;
  bool _accountSheetOpen = false;
  String? _lastSuggestedAccount;

  double get _totalAmount {
    final amount = double.tryParse(widget.amount.replaceAll(',', '')) ?? 0;
    return _quote?.total ?? amount;
  }

  double get _transactionFee => _quote?.fee ?? 0;

  @override
  void initState() {
    super.initState();
    _memoController.text = widget.memo;
  }

  @override
  void dispose() {
    _memoController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  void _onMemoChanged(String value) {
    widget.onMemoChanged(value);
  }

  Future<void> _accountChanged(String value) async {
    final account = value.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _selectedAccountNumber = account;
      _selectedRecipientName = '';
      _selectedBank = '';
      _selectedBankModel = null;
      _quote = null;
    });
    if (account.length != 10) {
      _lastSuggestedAccount = null;
      if (_suggestions.isNotEmpty) setState(() => _suggestions = const []);
      return;
    }
    try {
      final suggestions = await ref
          .read(transferRepositoryProvider)
          .suggestBanks(account);
      if (mounted && _selectedAccountNumber == account) {
        setState(() => _suggestions = suggestions);
        if (suggestions.isNotEmpty && _lastSuggestedAccount != account) {
          _lastSuggestedAccount = account;
          await _showSuggestedBanks(account, suggestions);
        }
      }
    } catch (_) {
      // The full bank list remains available if provider suggestions fail.
    }
  }

  Future<void> _showSuggestedBanks(
    String account,
    List<BankSuggestion> suggestions,
  ) async {
    final selected = await showDialog<BankSuggestion>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) =>
          MultipleBanksPopup(accountNumber: account, suggestions: suggestions),
    );
    if (selected == null || !mounted || _selectedAccountNumber != account) {
      return;
    }
    setState(() {
      _selectedBankModel = Bank(
        code: selected.bankCode,
        name: selected.bankName,
      );
      _selectedBank = selected.bankName;
      _selectedRecipientName = selected.accountName;
      _quote = null;
    });
    await _loadQuote();
  }

  Future<void> _chooseLiveBank() async {
    try {
      final result = await context.push<Map<String, dynamic>>(
        Routes.chooseBank,
        extra: ChooseBankArgs(suggestions: _suggestions),
      );
      if (result == null || !mounted) return;
      final code = result['code']?.toString() ?? '';
      final name = result['name']?.toString() ?? '';
      if (code.isEmpty || name.isEmpty) return;
      final bank = Bank(code: code, name: name);
      setState(() {
        _selectedBankModel = bank;
        _selectedBank = bank.name;
        _quote = null;
      });
      if (_selectedAccountNumber.length == 10) await _loadQuote();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
      }
    }
  }

  Future<void> _chooseRecipient() async {
    final result = await context.push<RecipientPickerResult>(
      Routes.recipientPick,
      extra: RecipientPickerArgs(
        amount: widget.amount,
        currency: widget.currency,
        memo: _memoController.text,
        onMemoChanged: widget.onMemoChanged,
      ),
    );
    if (result == null || !mounted) return;
    _accountController.text = result.accountNumber;
    setState(() {
      _selectedAccountNumber = result.accountNumber;
      _selectedBank = result.bankName;
      _selectedBankModel = Bank(code: result.bankCode, name: result.bankName);
      _selectedRecipientName = result.name;
      _selectedRecipientImage = result.imageUrl;
      _suggestions = const [];
      _quote = null;
    });
    await _loadQuote();
  }

  Future<void> _loadQuote({bool showResolvedSheet = true}) async {
    final bank = _selectedBankModel;
    final amount = double.tryParse(widget.amount.replaceAll(',', '')) ?? 0;
    if (bank == null || _selectedAccountNumber.length != 10 || amount <= 0) {
      return;
    }
    setState(() => _loading = true);
    try {
      final repository = ref.read(transferRepositoryProvider);
      final resolvedFuture = repository.resolveAccount(
        bankCode: bank.code,
        accountNumber: _selectedAccountNumber,
      );
      final quoteFuture = repository.quoteNgn(
        amount: amount,
        bankCode: bank.code,
        accountNumber: _selectedAccountNumber,
        narration: _memoController.text.trim().isEmpty
            ? 'TF Transfer'
            : _memoController.text.trim(),
      );
      final walletFuture = ref
          .read(walletProvider.future)
          .then<double?>(
            (wallet) => wallet.ngnBalance,
            onError: (_, _) => null,
          );
      final resolved = await resolvedFuture;
      final quote = await quoteFuture;
      final walletBalance = await walletFuture;
      if (!mounted) return;
      setState(() {
        _selectedRecipientName = resolved.accountName;
        _selectedRecipientImage = resolved.transfaUserMatched
            ? resolved.profileImageUrl
            : null;
        _selectedAccountNumber = resolved.accountNumber;
        _selectedBank = resolved.bankName;
        _selectedBankModel = Bank(
          code: resolved.bankCode,
          name: resolved.bankName,
        );
        _quote = quote;
      });
      if (showResolvedSheet) {
        await _showResolvedAccountSheet(resolved, quote, walletBalance);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFacingError(error))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmTransfer() async {
    if (_quote == null) await _loadQuote(showResolvedSheet: false);
    if (!mounted || _quote == null || _selectedBankModel == null) return;
    _continueToConfirmation();
  }

  Future<void> _showResolvedAccountSheet(
    ResolvedBankAccount resolved,
    TransferQuote quote,
    double? walletBalance,
  ) async {
    if (_accountSheetOpen || !mounted) return;
    _accountSheetOpen = true;
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(45)),
      ),
      builder: (sheetContext) => SingleAccountSheet(
        amount: widget.amount,
        currencySymbol: widget.currency.symbol,
        memo: _memoController.text,
        recipientName: resolved.accountName,
        recipientImageUrl: resolved.transfaUserMatched
            ? resolved.profileImageUrl
            : null,
        accountNumber: resolved.accountNumber,
        bankName: resolved.bankName,
        bankCode: resolved.bankCode,
        userBalance: walletBalance,
        transactionFee: quote.fee,
        totalAmount: quote.total,
        allowBankChange: false,
        onMemoChanged: (value) {
          _memoController.text = value;
          widget.onMemoChanged(value);
        },
        onConfirm: () => Navigator.pop(sheetContext, true),
      ),
    );
    _accountSheetOpen = false;
    if (confirm == true && mounted) _continueToConfirmation();
  }

  void _continueToConfirmation() {
    if (_quote == null || _selectedBankModel == null) return;
    final amount = double.tryParse(widget.amount.replaceAll(',', '')) ?? 0;
    ref.read(transferDraftProvider.notifier).state = TransferDraft(
      currency: TxCurrency.ngn,
      amount: amount,
      recipientName: _selectedRecipientName,
      recipientAccount: _selectedAccountNumber,
      bankName: _selectedBank,
      bankCode: _selectedBankModel!.code,
      memo: _memoController.text.trim(),
      quote: _quote,
    );
    final router = GoRouter.of(context);
    Navigator.pop(context);
    router.push(Routes.transferConfirm);
  }

  // Get the appropriate icon for the account number field
  Widget _getAccountIcon() {
    if (_selectedRecipientImage != null &&
        _selectedRecipientImage!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Image.network(
          _selectedRecipientImage!,
          width: 30,
          height: 30,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              SvgPicture.asset(Assets.contacts, width: 26, height: 26),
        ),
      );
    } else {
      return SvgPicture.asset(Assets.contacts, width: 26, height: 26);
    }
  }

  // Helper to get bank initials
  String _getBankInitials(String bankName) {
    if (bankName.toLowerCase() == 'access bank') return 'AB';
    if (bankName.toLowerCase() == 'first bank') return 'FB';
    if (bankName.toLowerCase() == 'zenith bank') return 'ZB';
    if (bankName.toLowerCase() == 'union bank') return 'UB';
    if (bankName.toLowerCase() == 'stanbic ibtc') return 'SI';

    final words = bankName.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return bankName.substring(0, 1).toUpperCase();
  }

  // Get bank gradient colors based on bank name
  (Color?, Color?) _getBankGradientsForName(String bankName) {
    switch (bankName.toLowerCase()) {
      case 'opay':
        return (const Color(0xFFFFFFFF), const Color(0xFFFFFFFF));
      case 'fcmb':
        return (const Color(0xFF5C2684), const Color(0xFF5C2684));
      case 'chase':
        return (const Color(0xFFFFFFFF), const Color(0xFFFFFFFF));
      case 'gtbank':
        return (const Color(0xFFE85A1F), const Color(0xFFE85A1F));
      case 'access bank':
        return (const Color(0xFFEF3E33), const Color(0xFFEF3E33));
      case 'first bank':
        return (const Color(0xFF003B71), const Color(0xFF003B71));
      case 'zenith bank':
        return (const Color(0xFFE60012), const Color(0xFFE60012));
      case 'uba':
        return (const Color(0xFFCC0000), const Color(0xFFCC0000));
      case 'kuda':
        return (const Color(0xFF40196D), const Color(0xFF40196D));
      case 'wema bank':
        return (const Color(0xFF6F2C91), const Color(0xFF6F2C91));
      case 'sterling bank':
        return (const Color(0xFFD8232A), const Color(0xFFD8232A));
      case 'palmpay':
        return (const Color(0xFF6238FB), const Color(0xFF6238FB));
      case 'moneypoint':
        return (const Color(0xFF0357EE), const Color(0xFF0357EE));
      case 'stanbic ibtc':
        return (const Color(0xFF0033A0), const Color(0xFF0033A0));
      case 'union bank':
        return (const Color(0xFF003E7E), const Color(0xFF003E7E));
      default:
        return (null, null);
    }
  }

  // Get the appropriate icon for the bank field
  Widget _getBankIcon() {
    if (_selectedBank.isNotEmpty) {
      if (_selectedBankLogo.isNotEmpty) {
        if (_selectedBankLogo.contains('.svg')) {
          return SvgPicture.asset(_selectedBankLogo, width: 22, height: 22);
        } else {
          return Image.asset(
            _selectedBankLogo,
            width: 22,
            height: 22,
            fit: BoxFit.contain,
          );
        }
      } else {
        final initials = _getBankInitials(_selectedBank);
        final gradients = _getBankGradientsForName(_selectedBank);
        final color1 = gradients.$1 ?? const Color(0xFF07B826);
        final color2 = gradients.$2 ?? const Color(0xFF4EE659);

        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color1, color2],
            ),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }
    // Default: show default bank icon with green gradient
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF07B826), Color(0xFF4EE659)],
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        Assets.bank,
        width: 12,
        height: 12,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (MediaQuery.of(context).size.height * 0.7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFB).withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(45),
          topRight: Radius.circular(45),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(45),
          topRight: Radius.circular(45),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                // Fixed Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const TransfaMark(size: 16, white: true),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Transfa',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                            fontSize: 24,
                            letterSpacing: 0.02,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFCFCFB,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(35),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Account Number Field — tapping this now opens
                        // the recipient picker, which routes straight
                        // into the next sheet on selection instead of
                        // returning a result here.
                        Container(
                          height: 62,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCFCFB),
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'To:',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 17,
                                  letterSpacing: 0.02,
                                  color: Color(0xFF8A8A8C),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _accountController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 10,
                                  onChanged: _accountChanged,
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 17,
                                    letterSpacing: 0.02,
                                    color: Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    hintText: 'Account number...',
                                    helperText: _selectedRecipientName.isEmpty
                                        ? null
                                        : _selectedRecipientName,
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                key: const Key('pay-sheet-recipient-picker'),
                                onTap: _chooseRecipient,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF07B826),
                                        Color(0xFF4EE659),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                  alignment: Alignment.center,
                                  child: _getAccountIcon(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Bank Center Field — restored. Kept as a
                        // standalone picker (ChooseBankScreen) since
                        // bank choice for the active flow now happens
                        // inside SingleAccountSheet instead.
                        GestureDetector(
                          onTap: _chooseLiveBank,
                          child: Container(
                            height: 62,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCFCFB),
                              borderRadius: BorderRadius.circular(35),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (_selectedBank.isNotEmpty)
                                  BankLogo(
                                    bankName: _selectedBank,
                                    bankCode: _selectedBankModel?.code,
                                    size: 30,
                                  )
                                else
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      gradient: _selectedBank.isNotEmpty
                                          ? LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                _selectedBankGradient1 ??
                                                    const Color(0xFFFFFFFF),
                                                _selectedBankGradient2 ??
                                                    const Color(0xFFFFFFFF),
                                              ],
                                            )
                                          : const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(0xFF07B826),
                                                Color(0xFF4EE659),
                                              ],
                                            ),
                                      borderRadius: BorderRadius.circular(35),
                                    ),
                                    alignment: Alignment.center,
                                    child: _getBankIcon(),
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _selectedBank.isEmpty
                                        ? 'Bank Center'
                                        : _selectedBank,
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 17,
                                      letterSpacing: 0.02,
                                      color: _selectedBank.isEmpty
                                          ? const Color(0xFF8A8A8C)
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  child: SvgPicture.asset(
                                    Assets.context,
                                    width: 12,
                                    height: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Send Amount Field
                        Container(
                          height: 105,
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCFCFB),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Send',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 17,
                                  letterSpacing: 0.02,
                                  color: Color(0xFF8A8A8C),
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          '${widget.currency.symbol}${widget.amount}',
                                      style: AppTypography.displayLarge
                                          .copyWith(
                                            color: Colors.black,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Message field — icon and text share the same
                        // vertical center via textAlignVertical.
                        Container(
                          height: 62,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCFCFB),
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                child: SvgPicture.asset(Assets.memo),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: TextField(
                                    controller: _memoController,
                                    onChanged: _onMemoChanged,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 17,
                                      letterSpacing: 0.02,
                                      color: Colors.black,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText:
                                          "Message: What's the money for?",
                                      hintStyle: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 17,
                                        letterSpacing: 0.02,
                                        color: Color(0xFF8A8A8C),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Pay with Field
                        Container(
                          height: 62,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCFCFB),
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(35),
                                ),
                                alignment: Alignment.center,
                                child: const TransfaMark(size: 12, white: true),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            '${widget.currency.symbol}${(ref.watch(walletProvider).valueOrNull?.ngnBalance ?? 0).toStringAsFixed(0)}',
                                        style: AppTypography.body.copyWith(
                                          color: Colors.grey,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Summary Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCFCFB),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Transaction Fee',
                                        style: TextStyle(
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 17,
                                          letterSpacing: 0.02,
                                          color: Color(0xFF8A8A8C),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${widget.currency.symbol}${_transactionFee.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 17,
                                        letterSpacing: 0.02,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(
                                height: 1,
                                color: Color(0xFFF0F0F0),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Total',
                                        style: TextStyle(
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 17,
                                          letterSpacing: 0.02,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${widget.currency.symbol}${_totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 17,
                                        letterSpacing: 0.02,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Pay Bubble - Touch to Confirm
                        GestureDetector(
                          onTap: _loading ? null : _confirmTransfer,
                          child: Container(
                            width: double.infinity,
                            height: 150,
                            padding: const EdgeInsets.all(30),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(58),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Touch to Confirm',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 17,
                                    letterSpacing: 0.02,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
