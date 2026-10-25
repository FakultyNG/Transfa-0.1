import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transfa/features/bottom_sheets/singleAccountSheet.dart';

void main() {
  testWidgets('resolved account sheet uses initials without CashDrop image', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleAccountSheet(
            amount: '25000',
            currencySymbol: '₦',
            memo: 'Dinner',
            recipientName: 'Ada Okafor',
            accountNumber: '0123456789',
            bankName: 'Access Bank',
            bankCode: '044',
            transactionFee: 50,
            totalAmount: 25050,
            userBalance: 100000,
            allowBankChange: false,
            onMemoChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AO'), findsOneWidget);
    expect(find.text('Ada Okafor'), findsWidgets);
    expect(find.text('0123456789'), findsOneWidget);
    expect(find.text('Access Bank'), findsOneWidget);
  });
}
