import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../features/pop-ups/currency_popup.dart';
import '../../../core/constants/assets.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/transfa_modal_header.dart';
import 'transfer_state.dart';
import '../../../data/mock_api/currency.dart';
import '../../../shared/widgets/homeFab.dart';

enum TransfaAiView { today, keypad }

class TransfaAiScreen extends ConsumerStatefulWidget {
  final TransfaAiView initialView;
  const TransfaAiScreen({super.key, this.initialView = TransfaAiView.today});
  @override
  ConsumerState<TransfaAiScreen> createState() => _TransfaAiScreenState();
}

class _TransfaAiScreenState extends ConsumerState<TransfaAiScreen> {
  late TransfaAiView _view = widget.initialView;
  String _digits = '0';
  AmountCurrency _currency = AmountCurrency.ngn;
  String _memo = '';
  String? _selectedTxName;

  void _toggle(TransfaAiView v) {
    if (_view != v) setState(() => _view = v);
  }

  void _selectTx(String name) {
    setState(() {
      _selectedTxName = _selectedTxName == name ? null : name;
    });
    context.push('/transactions/$name');
  }

  void _tap(String d) => setState(() {
    if (d == '.') {
      if (!_digits.contains('.')) _digits += '.';
    } else if (_digits == '0')
      _digits = d;
    else
      _digits += d;
  });
  void _back() => setState(() {
    if (_digits.isNotEmpty) {
      _digits = _digits.substring(0, _digits.length - 1);
      if (_digits.isEmpty) _digits = '0';
    }
  });

  String get _formatted {
    if (_digits.isEmpty || _digits == '0') return '0';
    final parts = _digits.split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    if (parts.length > 1) {
      buf.write('.');
      buf.write(parts[1]);
    }
    return buf.toString();
  }

  Future<void> _pickCurrency() async {
    final next = await showDialog<AmountCurrency>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      useSafeArea: true,
      builder: (context) => const CurrencyPopup(),
    );
    if (next != null && mounted) setState(() => _currency = next);
  }

  void _sendNGN() {
    final value = double.tryParse(_digits) ?? 0;
    if (value <= 0) return;
    ref.read(transferDraftProvider.notifier).state = ref
        .read(transferDraftProvider)
        .copyWith(currency: TxCurrency.ngn, amount: value, memo: _memo);
    context.push(Routes.transferDetails);
  }

  void _sendUSD() {
    final value = double.tryParse(_digits) ?? 0;
    if (value <= 0) return;
    final currency = _currency == AmountCurrency.cny
        ? TxCurrency.cny
        : TxCurrency.usd;
    ref.read(transferDraftProvider.notifier).state = ref
        .read(transferDraftProvider)
        .copyWith(currency: currency, amount: value, memo: _memo);
    context.push(Routes.transferDetails);
  }

  void _handleSend() {
    if (_currency == AmountCurrency.ngn) {
      _sendNGN();
    } else {
      _sendUSD();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundAlt,
    body: Stack(
      children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              final offset = child.key == const ValueKey(TransfaAiView.today)
                  ? const Offset(0, -0.04)
                  : const Offset(0, 0.04);
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: offset,
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              );
            },
            child: _view == TransfaAiView.today
                ? _TodayView(
                    key: ValueKey('today_${_currency.code}'),
                    currency: _currency,
                    selectedTxName: _selectedTxName,
                    onSelectTx: _selectTx,
                    transactions: ref.watch(transactionsProvider),
                  )
                : _KeypadView(
                    key: const ValueKey(TransfaAiView.keypad),
                    formatted: _formatted,
                    currency: _currency,
                    onTap: _tap,
                    onBack: _back,
                    onSend: _handleSend,
                    onPickCurrency: _pickCurrency,
                  ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                HomeFab(onTap: () => context.go(Routes.dashboard)),
                const SizedBox(width: 16),
                Container(
                  width: 250,
                  child: TodayKeypadTabs(
                    keypadActive: _view == TransfaAiView.keypad,
                    onTodayTap: () => _toggle(TransfaAiView.today),
                    onKeypadTap: () => _toggle(TransfaAiView.keypad),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _TodayView extends StatelessWidget {
  final AmountCurrency currency;
  final String? selectedTxName;
  final Function(String) onSelectTx;
  final AsyncValue<List<AppTransaction>> transactions;

  const _TodayView({
    super.key,
    required this.currency,
    this.selectedTxName,
    required this.onSelectTx,
    required this.transactions,
  });

  bool get _isUsd => currency == AmountCurrency.usd;

  @override
  Widget build(BuildContext context) {
    final items =
        transactions.valueOrNull
            ?.where(
              (item) => _isUsd
                  ? item.currency == TxCurrency.usd
                  : item.currency == TxCurrency.ngn,
            )
            .map(_fromTransaction)
            .toList() ??
        const <_Tx>[];
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Hero(isUsd: _isUsd),
        const SizedBox(height: 24),
        const _RecentsHeader(),
        const SizedBox(height: 14),
        if (transactions.isLoading)
          const Padding(
            padding: EdgeInsets.all(36),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (transactions.hasError)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              'Could not load transaction history.',
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
          )
        else if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(36),
            child: Text(
              'No transactions yet',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
          )
        else
          _TxGroup(
            items: items,
            selectedTxName: selectedTxName,
            onSelectTx: onSelectTx,
          ),
        const SizedBox(height: 140),
      ],
    );
  }

  _Tx _fromTransaction(AppTransaction transaction) {
    final amount = transaction.currency == TxCurrency.usd
        ? AppFormat.usd(transaction.amount)
        : AppFormat.ngn(transaction.amount);
    return _Tx(
      transactionId: transaction.id,
      avatar: _AvatarKind.card,
      name: transaction.counterpartyName,
      meta: transaction.bankName ?? transaction.memo ?? 'Transfa',
      direction: transaction.type == TxType.credit ? _Dir.received : _Dir.sent,
      whenText: _relativeTime(transaction.createdAt),
      status: transaction.status == TxStatus.failed
          ? _Status.unableToSend
          : transaction.status == TxStatus.pending
          ? _Status.processing
          : null,
      amount: amount,
    );
  }

  String _relativeTime(DateTime value) {
    final difference = DateTime.now().difference(value.toLocal());
    if (difference.inMinutes < 1) return 'Right now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    return '${difference.inDays}d ago';
  }
}

class _Hero extends StatelessWidget {
  final bool isUsd;
  const _Hero({this.isUsd = false});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 460,
    child: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            isUsd ? Assets.wallpaperFood : Assets.usdBillHand,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          left: 24,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUsd ? 'BEFORE YOU WAKE UP' : 'UNIVERSAL INCOME',
                style: AppTypography.caption.copyWith(
                  color: isUsd ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isUsd ? 'Transfa' : 'Transfa AI',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: isUsd ? 32 : 40,
                  fontWeight: FontWeight.w800,
                  color: isUsd ? Colors.white : Colors.black,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RecentsHeader extends StatelessWidget {
  const _RecentsHeader();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.access_time_filled_rounded,
              color: Color(0xFFFF9F0A),
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'Recents',
          style: AppTypography.displayMedium.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 30,
          ),
        ),
      ],
    ),
  );
}

enum _AvatarKind { spotify, card, connectic }

enum _Dir { sent, received }

enum _Status { unableToSend, processing }

class _Tx {
  final String? transactionId;
  final _AvatarKind avatar;
  final String name;
  final String meta;
  final _Dir? direction;
  final String? whenText;
  final _Status? status;
  final String amount;
  const _Tx({
    this.transactionId,
    required this.avatar,
    required this.name,
    required this.meta,
    required this.amount,
    this.direction,
    this.whenText,
    this.status,
  });
}

class _TxGroup extends StatelessWidget {
  final List<_Tx> items;
  final String? selectedTxName;
  final Function(String) onSelectTx;

  const _TxGroup({
    required this.items,
    this.selectedTxName,
    required this.onSelectTx,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26), // Reduced from 28 to 26
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _TxRow(
            tx: items[i],
            isSelected:
                selectedTxName == (items[i].transactionId ?? items[i].name),
            onTap: () => onSelectTx(items[i].transactionId ?? items[i].name),
          ),
          if (i < items.length - 1)
            const Divider(
              height: 1,
              indent: 80,
              endIndent: 16,
              color: Color(0xFFF0F0F0),
            ),
        ],
      ],
    ),
  );
}

class _TxRow extends StatelessWidget {
  final _Tx tx;
  final bool isSelected;
  final VoidCallback onTap;

  const _TxRow({
    required this.tx,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.black.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18), // Reduced from 20 to 18
      ),
      child: Row(
        children: [
          SizedBox(width: 52, height: 52, child: _Avatar(tx: tx)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.name,
                  style: AppTypography.bodyStrong.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.meta,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                _SubLine(tx: tx),
              ],
            ),
          ),
          Text(
            tx.amount,
            style: AppTypography.bodyStrong.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              decorationColor: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SubLine extends StatelessWidget {
  final _Tx tx;
  const _SubLine({required this.tx});
  @override
  Widget build(BuildContext context) {
    if (tx.status == _Status.unableToSend)
      return Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: Color(0xFFFF375F),
          ),
          const SizedBox(width: 4),
          Text(
            'Unable to Send',
            style: AppTypography.caption.copyWith(
              color: const Color(0xFFFF375F),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    if (tx.status == _Status.processing)
      return Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: Color(0xFFFF9F0A),
          ),
          const SizedBox(width: 4),
          Text(
            'Processing',
            style: AppTypography.caption.copyWith(
              color: const Color(0xFFFF9F0A),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    return Row(
      children: [
        SvgPicture.asset(
          tx.direction == _Dir.sent ? Assets.arrowUp : Assets.arrowDown,
          width: 14,
          height: 14,
          fit: BoxFit.contain,
        ),

        const SizedBox(width: 4),
        Text(
          tx.whenText ?? '',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final _Tx tx;
  const _Avatar({required this.tx});
  @override
  Widget build(BuildContext context) {
    switch (tx.avatar) {
      case _AvatarKind.spotify:
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1ED760),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(10),
          child: SvgPicture.asset(Assets.spotifyIcon, fit: BoxFit.contain),
        );
      case _AvatarKind.card:
        return const _CardAvatar();
      case _AvatarKind.connectic:
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFF375F),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            'CCC',
            style: AppTypography.bodyStrong.copyWith(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
    }
  }
}

class _CardAvatar extends StatelessWidget {
  const _CardAvatar();
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      Transform.rotate(
        angle: -0.45,
        child: const _CardEllipse(color: Color(0xFFFF9F0A)),
      ),
      Transform.rotate(
        angle: 0.45,
        child: const _CardEllipse(color: Color(0xFF34C759)),
      ),
      const _CardEllipse(color: Color(0xFF1EA7FF)),
    ],
  );
}

class _CardEllipse extends StatelessWidget {
  final Color color;
  const _CardEllipse({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 36,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white, width: 1.4),
    ),
  );
}

class _KeypadView extends StatelessWidget {
  final String formatted;
  final AmountCurrency currency;
  final void Function(String) onTap;
  final VoidCallback onBack;
  final GestureTapCallback onSend;
  final VoidCallback onPickCurrency;
  const _KeypadView({
    super.key,
    required this.formatted,
    required this.currency,
    required this.onTap,
    required this.onBack,
    required this.onSend,
    required this.onPickCurrency,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 110),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onPickCurrency,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: currency == AmountCurrency.usd
                    ? SvgPicture.asset(
                        Assets.spendCurrency,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      )
                    : currency == AmountCurrency.ngn
                    ? SvgPicture.asset(
                        Assets.Nigerian_Flag,
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      )
                    : SvgPicture.asset(
                        Assets.China_Flag,
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 50),
          RichText(
            text: TextSpan(
              style: AppTypography.displayLarge.copyWith(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.0,
              ),
              children: [
                TextSpan(text: currency.symbol),
                TextSpan(text: formatted),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter Amount',
            style: AppTypography.subheading.copyWith(
              color: AppColors.textMuted,
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
          Expanded(
            child: _Keypad(onTap: onTap, onBack: onBack),
          ),
          GestureDetector(
            onTap: onSend,
            child: Container(
              child: SvgPicture.asset(
                Assets.sendIcon,
                width: 78,
                height: 78,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

class _Keypad extends StatelessWidget {
  final void Function(String) onTap;
  final VoidCallback onBack;
  const _Keypad({required this.onTap, required this.onBack});

  Widget _circle(String d) => GestureDetector(
    onTap: () => onTap(d),
    child: Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        d,
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
      ),
    ),
  );
  Widget _dot() => GestureDetector(
    onTap: () => onTap('.'),
    child: Container(
      width: 78,
      height: 78,
      alignment: Alignment.center,
      child: const Icon(Icons.circle, size: 10, color: Colors.black),
    ),
  );
  Widget _delete() => GestureDetector(
    onTap: onBack,
    child: Container(
      width: 78,
      height: 78,
      alignment: Alignment.center,
      child: Container(
        width: 78,
        height: 78,

        alignment: Alignment.center,
        child: SvgPicture.asset(
          Assets.deleteIcon,
          width: 32,
          height: 26,
          fit: BoxFit.contain,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    Widget row(List<Widget> cells) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: cells,
      ),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        row([_circle('1'), _circle('2'), _circle('3')]),
        row([_circle('4'), _circle('5'), _circle('6')]),
        row([_circle('7'), _circle('8'), _circle('9')]),
        row([_dot(), _circle('0'), _delete()]),
      ],
    );
  }
}
