import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medalert/utils/constants.dart';

void main() {
  test('AppConstants.appName is MedAlert', () {
    expect(AppConstants.appName, 'MedAlert');
  });

  testWidgets('Basic MaterialApp renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
