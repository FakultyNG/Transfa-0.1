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
    expect(find.text('Suggestions'), findsOneWidget);
    expect(find.text('All Banks'), findsOneWidget);
    expect(find.text('Access Bank'), findsWidgets);
    expect(find.text('GTBank'), findsWidgets);
    expect(find.text('First City Monument Bank'), findsWidgets);
  });
}
