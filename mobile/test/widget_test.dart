import 'package:flutter_test/flutter_test.dart';

import 'package:logisync_mobile/app.dart';

void main() {
  testWidgets('renders LogiSync restoring state', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('RESTORING SESSION'), findsOneWidget);
    expect(
      find.text('Checking saved credentials and syncing with the API.'),
      findsOneWidget,
    );
  });
}
