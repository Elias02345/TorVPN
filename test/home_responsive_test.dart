import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tortunnel/src/app.dart';

void main() {
  testWidgets('home keeps locked readiness visible on desktop', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TorTunnelApp());

    expect(find.text('Connect gesperrt'), findsOneWidget);
    expect(find.textContaining('Setup nicht bereit'), findsWidgets);
    expect(find.byIcon(Icons.devices_rounded), findsOneWidget);
  });

  testWidgets('home keeps locked readiness visible on mobile', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TorTunnelApp());

    expect(find.text('Connect gesperrt'), findsOneWidget);
    expect(find.textContaining('Setup nicht bereit'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
