import 'package:flutter_test/flutter_test.dart';
import 'package:servease/main.dart';

void main() {
  testWidgets('ServEase app launches', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Verify app builds without crashing
    expect(find.byType(MyApp), findsOneWidget);
  });
}
