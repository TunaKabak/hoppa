import 'package:flutter_test/flutter_test.dart';
import 'package:courier_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic pump test for CourierApp
    await tester.pumpWidget(const CourierApp());
  });
}
