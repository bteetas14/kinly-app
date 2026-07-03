import 'package:flutter_test/flutter_test.dart';
import 'package:kinly/core/api_client.dart';

void main() {
  test('uses valid default API base for the current platform', () {
    expect(apiBaseUrl, isNotEmpty);
    expect(normalizedApiBaseUrl.endsWith('/'), isTrue);
  });

  test('normalizes request paths for proxy base URL', () {
    expect(apiPath('/products'), 'products');
    expect(apiPath('products/search'), 'products/search');
  });
}
