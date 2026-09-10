import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders basic SnapGym shell', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('SnapGym'))),
      ),
    );

    expect(find.text('SnapGym'), findsOneWidget);
  });
}
