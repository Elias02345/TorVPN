import 'package:flutter/services.dart';

import 'mock_core_client.dart';
import 'core_models.dart';

class AndroidVpnClient extends MockCoreClient {
  static const MethodChannel _channel = MethodChannel(
    'org.tortunnel.tortunnel/vpn',
  );

  @override
  Future<void> connect() async {
    final enabledExceptions = appExceptions.where((item) => item.enabled);
    if (connectionMode == ConnectionMode.strict &&
        enabledExceptions.isNotEmpty) {
      status = status.copyWith(
        state: ConnectionStateKind.blockedByKillswitch,
        health: TunnelHealth.blockedByKillSwitch,
        message:
            'Strict Mode blockiert App-Ausnahmen. Entferne Ausnahmen oder nutze Kompatibilitaet.',
      );
      notifyListeners();
      return;
    }

    status = ConnectionStatus(
      state: ConnectionStateKind.connecting,
      mode: connectionMode,
      health: TunnelHealth.reconnecting,
      profile: selectedProfile,
      bridgeConfig: bridgeConfig,
      bootstrapPercent: 20,
      killSwitchActive: false,
      dnsProtected: false,
      udpBlocked: false,
      ipv6Blocked: false,
      fallbackActive: false,
      message: 'Android fragt jetzt die VPN-Berechtigung an.',
      releaseBlockers: const [],
    );
    notifyListeners();

    try {
      final prepared = await _channel.invokeMapMethod<String, dynamic>(
        'prepareVpn',
      );
      if (prepared?['prepared'] != true) {
        status = status.copyWith(
          state: ConnectionStateKind.disconnected,
          health: TunnelHealth.blockedByKillSwitch,
          bootstrapPercent: 0,
          message: 'VPN-Berechtigung wurde abgebrochen.',
        );
        notifyListeners();
        return;
      }

      status = status.copyWith(
        bootstrapPercent: 72,
        message: 'VPN-Berechtigung erteilt. Tunnel wird gestartet.',
      );
      notifyListeners();

      await _channel.invokeMapMethod<String, dynamic>('startVpn', {
        'profile_id': selectedProfile.id,
        'exit_countries': selectedProfile.exitCountries,
        'mode': connectionMode.name,
      });

      status = ConnectionStatus(
        state: ConnectionStateKind.degraded,
        mode: connectionMode,
        health: TunnelHealth.reducedProtection,
        profile: selectedProfile,
        bridgeConfig: bridgeConfig,
        exitCountry: selectedProfile.exitCountries.isEmpty
            ? null
            : selectedProfile.exitCountries.first,
        bootstrapPercent: 100,
        killSwitchActive: true,
        dnsProtected: false,
        udpBlocked: false,
        ipv6Blocked: false,
        fallbackActive: false,
        message:
            'Android VPN ist aktiv. Tor-Routing und Leak-Schutz sind Alpha und noch nicht verifiziert.',
        releaseBlockers: const [
          'Tor packet routing is not production verified.',
          'Device leak matrix has not passed.',
          'Stable release remains blocked.',
        ],
      );
      notifyListeners();
    } on PlatformException catch (error) {
      status = status.copyWith(
        state: ConnectionStateKind.error,
        health: TunnelHealth.error,
        bootstrapPercent: 0,
        message: error.message ?? 'Android VPN konnte nicht gestartet werden.',
      );
      notifyListeners();
    }
  }

  @override
  void disconnect() {
    _channel.invokeMethod<void>('stopVpn');
    status = ConnectionStatus.disconnected().copyWith(message: 'VPN getrennt.');
    lastVerification = null;
    notifyListeners();
  }
}
