import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tortunnel/src/core/android_vpn_client.dart';
import 'package:tortunnel/src/core/core_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('android client requests permission and starts vpn service', () async {
    const channel = MethodChannel('org.tortunnel.tortunnel/vpn');
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'prepareVpn') {
            return {'prepared': true, 'cancelled': false};
          }
          if (call.method == 'startVpn') {
            return {'started': true};
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final core = AndroidVpnClient();

    await core.connect();

    expect(calls, ['prepareVpn', 'startVpn']);
    expect(core.status.state, ConnectionStateKind.degraded);
    expect(core.status.isActive, isTrue);
    expect(core.status.message, contains('Android VPN ist aktiv'));
  });
}
