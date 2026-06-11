import 'package:flutter_test/flutter_test.dart';
import 'package:tortunnel/src/core/core_models.dart';
import 'package:tortunnel/src/core/mock_core_client.dart';

void main() {
  test('strict connect stays locked until release evidence passes', () async {
    final core = MockCoreClient();

    await core.connect();

    expect(core.status.state, ConnectionStateKind.blockedByKillswitch);
    expect(core.status.health, TunnelHealth.blockedByKillSwitch);
    expect(core.status.killSwitchActive, isTrue);
    expect(core.status.dnsProtected, isFalse);
    expect(core.status.udpBlocked, isFalse);
    expect(core.status.ipv6Blocked, isFalse);
    expect(core.status.message, contains('Connect is locked'));
    expect(core.releaseReadiness.canAttemptRealConnection, isFalse);
  });

  test(
    'compatibility mode still cannot bypass release evidence gates',
    () async {
      final core = MockCoreClient()
        ..setConnectionMode(ConnectionMode.compatibilityReducedProtection);

      await core.connect();

      expect(core.status.state, ConnectionStateKind.blockedByKillswitch);
      expect(core.status.health, TunnelHealth.blockedByKillSwitch);
      expect(core.status.message, contains('Connect is locked'));
    },
  );

  test('strict mode prevents enabling app exceptions', () {
    final core = MockCoreClient();

    core.toggleAppException('com.bank.mobile', true);

    expect(core.appExceptions.first.enabled, isFalse);
    expect(core.status.health, TunnelHealth.blockedByKillSwitch);
  });

  test('leak self-test blocks stable until native adapter is ready', () {
    final core = MockCoreClient();

    final report = core.runLeakSelfTest();

    expect(report.stableReleaseAllowed, isFalse);
    expect(report.results, isNotEmpty);
  });

  test('diagnostic export is local and redacted by design', () {
    final core = MockCoreClient();

    final diagnostics = core.exportDiagnostics();

    expect(diagnostics, contains('Telemetry: none'));
    expect(diagnostics, contains('Upload: manual only'));
  });
}
