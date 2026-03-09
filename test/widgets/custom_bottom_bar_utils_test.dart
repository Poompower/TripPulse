import 'package:flutter_test/flutter_test.dart';
import 'package:trippulse/widgets/custom_bottom_bar.dart';

void main() {
  test('CustomBottomBar.getIndexFromRoute maps primary routes correctly', () {
    expect(CustomBottomBar.getIndexFromRoute('/trip-list-screen'), 0);
    expect(CustomBottomBar.getIndexFromRoute('/places-search-screen'), 1);
    expect(CustomBottomBar.getIndexFromRoute('/general-map-screen'), 2);
    expect(CustomBottomBar.getIndexFromRoute('/profile-screen'), 3);
  });

  test('CustomBottomBar.getIndexFromRoute defaults to trips for unknown route', () {
    expect(CustomBottomBar.getIndexFromRoute('/unknown'), 0);
    expect(CustomBottomBar.getIndexFromRoute(null), 0);
  });
}
