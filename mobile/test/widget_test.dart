import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kinly/core/api_client.dart';
import 'package:kinly/main.dart';

void main() {
  testWidgets('renders Kinly app shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_FakeApiClient()),
        ],
        child: const KinlyApp(),
      ),
    );
    await tester.pump();
    expect(find.text('Kinly'), findsOneWidget);
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(token: null);

  @override
  Future<Map<String, dynamic>> getMap(String path,
      {Map<String, dynamic>? query}) async {
    return {'data': <dynamic>[], 'page': 1, 'page_size': 20, 'total': 0};
  }
}
