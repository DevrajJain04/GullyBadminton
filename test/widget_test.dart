// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:gully_badminton/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GullyBadmintonApp());
    expect(find.text('Gully Badminton'), findsOneWidget);
  });
}
