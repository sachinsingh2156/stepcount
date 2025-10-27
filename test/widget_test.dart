// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stepcounter/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartStepCounterApp());

    // Verify that our app has loaded
    expect(find.text('Smart Step Counter'), findsOneWidget);
  });
}
