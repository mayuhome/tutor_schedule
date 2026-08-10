import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_schedule/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TutorScheduleApp());
    expect(find.text('家教日程管家'), findsOneWidget);
  });
}
