import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trippulse/places/widgets/search_bar_widget.dart';

void main() {
  testWidgets('SearchBarWidget triggers search on submit', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    var searchCallCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchBarWidget(
            controller: controller,
            onSearch: () => searchCallCount++,
            onOpenFilter: () {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'museum');
    await tester.testTextInput.receiveAction(TextInputAction.search);

    expect(searchCallCount, 1);
  });

  testWidgets('SearchBarWidget opens filter when filter icon pressed', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    var filterCallCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchBarWidget(
            controller: controller,
            onSearch: () {},
            onOpenFilter: () => filterCallCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    expect(filterCallCount, 1);
  });
}
