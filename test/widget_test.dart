import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tortunnel/src/app.dart';

void main() {
  testWidgets('TorTunnel shell renders and strict connection blocks safely', (
    tester,
  ) async {
    await tester.pumpWidget(const TorTunnelApp());

    expect(find.text('TorTunnel'), findsWidgets);
    expect(find.text('Verbinden'), findsOneWidget);
    expect(find.byIcon(Icons.power_settings_new_rounded), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('connect-button')));
    await tester.pump();

    expect(find.textContaining('Starting Tor daemon'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 950));
    expect(find.text('Kill-Switch blockiert'), findsOneWidget);
    expect(find.text('Verbinden'), findsOneWidget);
  });
}
