import 'package:flutter_test/flutter_test.dart';
import 'package:kinogo/core/api/categories_config.dart';

void main() {
  test('category catalogue is populated', () {
    expect(kCategories, isNotEmpty);
    expect(kCategories.any((c) => c.slug == 'filmy'), isTrue);
  });
}
