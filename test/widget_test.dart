import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_sample/main.dart';

void main() {
  testWidgets('アプリが起動してナビゲーションバーが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const RfwSampleApp());

    expect(find.text('Basic'), findsOneWidget);
    expect(find.text('Data Binding'), findsOneWidget);
    expect(find.text('Live Editor'), findsOneWidget);
  });
}
