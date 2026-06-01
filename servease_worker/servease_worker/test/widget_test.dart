import 'package:flutter_test/flutter_test.dart';
import 'package:servease_worker/main.dart';

void main() {
  testWidgets('Worker app builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const WorkerApp());

    // Just ensure app loads
    expect(find.byType(WorkerApp), findsOneWidget);
  });
}
