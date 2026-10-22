import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transfa/data/models/bank.dart';
import 'package:transfa/features/pop-ups/multiple_banks_popup.dart';
import 'package:transfa/features/pop-ups/no_internet_popup.dart';
import 'package:transfa/providers/connectivity_provider.dart';
import 'package:transfa/shared/widgets/connectivity_observer.dart';

class _FakeConnectivityNotifier extends ConnectivityNotifier {
  _FakeConnectivityNotifier(bool connected) : super(autoStart: false) {
    state = ConnectivityState(isConnected: connected);
  }

  void setConnected(bool connected) {
    state = ConnectivityState(isConnected: connected);
  }
}

void main() {
  testWidgets('No Internet popup follows live connectivity state', (
    tester,
  ) async {
    final connectivity = _FakeConnectivityNotifier(false);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectivityProvider.overrideWith((_) => connectivity)],
        child: const MaterialApp(
          home: ConnectivityObserver(child: Text('Home')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(NoInternetPopup), findsOneWidget);

    connectivity.setConnected(true);
    await tester.pumpAndSettle();
    expect(find.byType(NoInternetPopup), findsNothing);
  });

  testWidgets('Multiple Banks popup returns the selected live suggestion', (
    tester,
  ) async {
    const suggestions = [
      BankSuggestion(
        accountName: 'EDWARD ROBERTS',
        accountNumber: '0123456789',
        bankCode: '232',
        bankName: 'Sterling Bank',
        confidence: 96,
      ),
      BankSuggestion(
        accountName: 'EDWARD ROBERTS',
        accountNumber: '0123456789',
        bankCode: '999',
        bankName: 'OPay',
        confidence: 82,
      ),
    ];
    BankSuggestion? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selected = await showDialog<BankSuggestion>(
                context: context,
                builder: (_) => const MultipleBanksPopup(
                  accountNumber: '0123456789',
                  suggestions: suggestions,
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('EDWARD ROBERTS'), findsOneWidget);
    expect(find.text('0123456789'), findsOneWidget);
    expect(find.text('Sterling Bank'), findsOneWidget);

    await tester.ensureVisible(find.text('Sterling Bank'));
    await tester.tap(find.text('Sterling Bank'));
    await tester.pumpAndSettle();
    expect(selected?.bankCode, '232');
  });
}
