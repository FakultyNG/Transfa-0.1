import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transfa/data/models/user.dart';
import 'package:transfa/features/dashboard/presentation/share_account_screen.dart';

void main() {
  testWidgets('account share card uses live bank label and account details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const user = AppUser(
      id: 'user-1',
      fullName: 'Magic Payma',
      email: '',
      phone: '2348012345678',
      isVerified: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AccountShareCard(
              user: user,
              bankName: 'Strowallet MFB',
              accountNumber: '7032084888',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Magic Payma'), findsOneWidget);
    expect(find.text('Strowallet MFB'), findsOneWidget);
    expect(find.text('703 208 4888'), findsOneWidget);
    expect(find.text('Account Number'), findsNothing);
  });
}
