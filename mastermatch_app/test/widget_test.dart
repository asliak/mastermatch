import 'package:flutter_test/flutter_test.dart';
import 'package:mastermatch_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MasterMatchApp());
    expect(find.byType(MasterMatchApp), findsOneWidget);
  });
}
