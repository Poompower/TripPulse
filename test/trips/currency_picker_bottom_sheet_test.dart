import 'package:flutter_test/flutter_test.dart';
import 'package:trippulse/trips/widgets/currency_picker_bottom_sheet.dart';

void main() {
  test('currencyFlagEmoji returns expected flag for known currency', () {
    expect(currencyFlagEmoji('THB'), '🇹🇭');
    expect(currencyFlagEmoji('JPY'), '🇯🇵');
  });

  test('currencyFlagEmoji returns blanks for unsupported currency', () {
    expect(currencyFlagEmoji('XYZ'), '  ');
  });
}
