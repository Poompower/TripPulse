import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trippulse/trips/widgets/custom_input.dart';

void main() {
  testWidgets('CustomInputField shows label, hint and icon', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomInputField(
            label: 'Budget',
            hint: 'Enter budget',
            controller: controller,
            icon: Icons.attach_money,
          ),
        ),
      ),
    );

    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Enter budget'), findsOneWidget);
    expect(find.byIcon(Icons.attach_money), findsOneWidget);
  });

  testWidgets('CustomInputField passes maxLength to TextField', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomInputField(
            label: 'Title',
            hint: 'Trip title',
            controller: controller,
            maxLength: 20,
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLength, 20);
  });
}
