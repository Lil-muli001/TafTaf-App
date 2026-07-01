import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taftaf/app.dart';

void main() {
  testWidgets('TafTaf app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TafTafApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
