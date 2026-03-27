import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';

void main() {
  testWidgets('shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
