import 'package:flutter_test/flutter_test.dart';

import 'package:logisync_mobile/app.dart';

void main() {
  testWidgets('renders LogiSync login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('LOGISYNC'), findsOneWidget);
    expect(find.text('Operator Authentication'), findsOneWidget);
    expect(find.text('Initialize Sync'.toUpperCase()), findsOneWidget);
  });
}
