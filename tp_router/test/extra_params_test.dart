import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tp_router/tp_router.dart';
import '../example/lib/models/memory_detail.dart';
import '../example/lib/routes/route.gr.dart';

void main() {
  testWidgets('MemoryDetailRoute uses default value when extra is missing',
      (WidgetTester tester) async {
    // Create a mock TpRouteData with empty extra
    final data = TpRouteData.fromPath('/memory-detail', extra: {});

    // Build the widget using the generated routeInfo.builder
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
    final data =
        TpRouteData.fromPath('/memory-detail', extra: {'memory': customMemory});

    // Build the widget
    await tester.pumpWidget(MaterialApp(
      home: MemoryDetailRoute.routeInfo.builder(data),
    ));

    // Verify it shows the custom value
    expect(find.textContaining('id: custom'), findsOneWidget);
    expect(find.textContaining('content: Custom Content'), findsOneWidget);
  });
}
