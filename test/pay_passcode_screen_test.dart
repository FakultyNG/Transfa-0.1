import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transfa/features/auth/presentation/unlock_screens.dart';

void main() {
  testWidgets(
    'payment passcode returns the entered code to the transfer flow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => const PayPasscodeScreen(),
                    ),
                  );
                },
                child: const Text('Authorize'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Authorize'));
      await tester.pumpAndSettle();
      for (final digit in ['1', '2', '3', '4', '5']) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, '12345');
      expect(find.text('Authorize'), findsOneWidget);
    },
  );
}
