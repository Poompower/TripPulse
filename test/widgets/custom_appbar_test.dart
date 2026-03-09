import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trippulse/widgets/custom_appbar.dart';

void main() {
  testWidgets('CustomAppBar.searchPlace renders search hint UI', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(appBar: CustomAppBar.searchPlace(), body: SizedBox()),
      ),
    );

    expect(find.text('Search place (e.g. Tokyo, Japan)'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}
