import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tortunnel/src/app.dart';

void main() {
  testWidgets('home keeps simple connection controls visible on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TorTunnelApp());

    expect(find.text('Verbinden'), findsOneWidget);
    expect(find.text('Nicht verbunden'), findsOneWidget);
    expect(find.byKey(const ValueKey('country-select')), findsOneWidget);
  });

  testWidgets('home keeps simple connection controls visible on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TorTunnelApp());

    expect(find.text('Verbinden'), findsOneWidget);
    expect(find.text('Nicht verbunden'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
