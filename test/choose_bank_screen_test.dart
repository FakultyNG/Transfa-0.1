import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transfa/data/models/bank.dart';
import 'package:transfa/data/repositories/repositories.dart';
import 'package:transfa/features/transfers/presentation/choose_bank_screen.dart';

void main() {
  testWidgets('original Bank Center renders banks from the live provider', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ngnBanksProvider.overrideWith(
            (_) async => const [
              Bank(code: '044', name: 'Access Bank'),
              Bank(code: '058', name: 'GTBank'),
              Bank(code: '214', name: 'First City Monument Bank'),
            ],
          ),
        ],
        child: const MaterialApp(home: ChooseBankScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bank Center'), findsOneWidget);
    expect(find.text('Suggestions'), findsNothing);
    expect(find.text('All Banks'), findsOneWidget);
    expect(find.text('Access Bank'), findsWidgets);
    expect(find.text('GTBank'), findsWidgets);
    expect(find.text('First City Monument Bank'), findsWidgets);
  });

  test(
    'suggestions keep confidence order, remove duplicates, and cap at five',
    () {
      final ranked = rankBankSuggestions([
        for (var index = 0; index < 6; index++)
          BankSuggestion(
            accountName: 'TEST USER',
            accountNumber: '0123456789',
            bankCode: index == 5 ? '0' : '$index',
            bankName: 'Bank $index',
            confidence: 70 + index.toDouble(),
          ),
        const BankSuggestion(
          accountName: 'TEST USER',
          accountNumber: '0123456789',
          bankCode: '4',
          bankName: 'Duplicate Bank',
          confidence: 69,
        ),
      ]);

      expect(ranked, hasLength(5));
      expect(ranked.map((item) => item.bankCode).toSet(), hasLength(5));
      expect(
        ranked.map((item) => item.confidence),
        orderedEquals([75, 74, 73, 72, 71]),
      );
    },
  );

  test('popular banks sort ahead of the alphabetical remainder', () {
    final banks = ['Unity Bank', 'Zenith Bank', 'Access Bank', 'Abbey MFB']
      ..sort(compareBankNamesByPopularity);

    expect(
      banks,
      orderedEquals(['Access Bank', 'Zenith Bank', 'Abbey MFB', 'Unity Bank']),
    );
  });
}
