import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/models/memory_detail.dart';
import 'package:example/routes/route.gr.dart';
import 'package:tp_router/tp_router.dart';

void main() {
  testWidgets('MemoryDetailRoute uses default value when extra is missing',
      (WidgetTester tester) async {
    // Create a mock TpRouteData with empty extra
    final data = TpRouteData.fromPath('/memory-detail', extra: {
      'memory2': const MemoryDetail(id: 'required', content: 'Required')
    });

    // Build the widget using the generated routeInfo.builder
    // We use builder directly to test the extraction logic
    await tester.pumpWidget(MaterialApp(
      home: MemoryDetailRoute.routeInfo.builder(data),
    ));

    // Verify it shows the internal default value
    expect(find.textContaining('id: internal'), findsOneWidget);
    expect(find.textContaining('content: Internal Default'), findsOneWidget);
  });

  testWidgets('MemoryDetailRoute uses provided value when extra is present',
      (WidgetTester tester) async {
    const customMemory = MemoryDetail(id: 'custom', content: 'Custom Content');

    // Create a mock TpRouteData with custom extra
    final data = TpRouteData.fromPath('/memory-detail',
        extra: {'memory': customMemory, 'memory2': customMemory});

    // Build the widget
    await tester.pumpWidget(MaterialApp(
      home: MemoryDetailRoute.routeInfo.builder(data),
    ));

    // Verify it shows the custom value
    expect(find.textContaining('id: custom'), findsOneWidget);
    expect(find.textContaining('content: Custom Content'), findsOneWidget);
  });
}
