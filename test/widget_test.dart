import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:homework_recorder/app.dart';

void main() {
  testWidgets('StudyRecorderApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: StudyRecorderApp()),
    );

    // Verify that the app builds successfully.
    expect(find.text('记录页面'), findsOneWidget);
  });
}
