import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transfa/features/transfers/presentation/transfa_ai_screen.dart';

void main() {
  testWidgets('send and delete controls remain visible on a short screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TransfaAiScreen(initialView: TransfaAiView.keypad),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final send = find.byKey(const Key('send-money-submit'));
    final delete = find.byKey(const Key('send-money-delete'));

    expect(send, findsOneWidget);
    expect(delete, findsOneWidget);
    expect(tester.getBottomRight(send).dy, lessThanOrEqualTo(640));
    expect(tester.getBottomRight(delete).dy, lessThanOrEqualTo(640));

    await tester.tap(find.text('1'));
    await tester.pump();
    expect(_amountText('₦1'), findsOneWidget);

    await tester.tap(delete);
    await tester.pump();
    expect(_amountText('₦0'), findsOneWidget);
  });
}

Finder _amountText(String value) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText() == value,
);
