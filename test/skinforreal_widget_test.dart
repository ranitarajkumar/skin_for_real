import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skin_for_real/main.dart';
import 'package:skin_for_real/theme_provider.dart';

void main() {
  testWidgets('SkinForReal launches and shows Take a Picture button',
      (WidgetTester tester) async {
    // Wrap app with the necessary provider
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const SkinForRealApp(),
      ),
    );

    // Wait for UI to settle
    await tester.pumpAndSettle();

    // Verify "Take a Picture" button is shown
    expect(find.text('Take a Picture'), findsOneWidget);
  });
}
