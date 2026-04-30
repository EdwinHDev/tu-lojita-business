import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
  });
}
