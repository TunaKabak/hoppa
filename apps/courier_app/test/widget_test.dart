import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_network/core_network.dart';
import 'package:courier_app/main.dart';
import 'package:courier_app/src/screens/auth/courier_login_screen.dart';

class _TestAuthController extends AuthController {
  @override
  AuthState build() => AuthInitial();
}

void main() {
  testWidgets('CourierApp mounts CourierLoginScreen when unauthenticated', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(
            ApiClient(baseUrl: 'http://127.0.0.1:3000'),
          ),
          authControllerProvider.overrideWith(_TestAuthController.new),
        ],
        child: const CourierApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CourierLoginScreen), findsOneWidget);
    expect(find.text('Hoppa Kurye'), findsOneWidget);
  });
}
