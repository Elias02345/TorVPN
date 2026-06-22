import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'core_client.dart';
import 'core_models.dart';

typedef _CreateNative = Pointer<Void> Function();
typedef _DestroyNative = Void Function(Pointer<Void>);
typedef _JsonNoArgNative = Pointer<Utf8> Function(Pointer<Void>);
typedef _JsonOneArgNative =
    Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);
typedef _FreeStringNative = Void Function(Pointer<Utf8>);

typedef _CreateDart = Pointer<Void> Function();
typedef _DestroyDart = void Function(Pointer<Void>);
typedef _JsonNoArgDart = Pointer<Utf8> Function(Pointer<Void>);
typedef _JsonOneArgDart = Pointer<Utf8> Function(Pointer<Void>, Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

class TorTunnelFfiLibrary {
  TorTunnelFfiLibrary._(this._library)
    : _create = _library.lookupFunction<_CreateNative, _CreateDart>(
        'tt_core_create',
      ),
      _destroy = _library.lookupFunction<_DestroyNative, _DestroyDart>(
        'tt_core_destroy',
      ),
      _freeString = _library.lookupFunction<_FreeStringNative, _FreeStringDart>(
        'tt_core_free_string',
      ),
      _connect = _library.lookupFunction<_JsonOneArgNative, _JsonOneArgDart>(
        'tt_core_connect',
      ),
      _disconnect = _library.lookupFunction<_JsonNoArgNative, _JsonNoArgDart>(
        'tt_core_disconnect',
      ),
      _startTor = _library.lookupFunction<_JsonOneArgNative, _JsonOneArgDart>(
        'tt_core_start_tor',
      ),
      _stopTor = _library.lookupFunction<_JsonNoArgNative, _JsonNoArgDart>(
        'tt_core_stop_tor',
      ),
      _rotateIdentity = _library
          .lookupFunction<_JsonNoArgNative, _JsonNoArgDart>(
            'tt_core_rotate_identity',
          ),
      _setAppExceptions = _library
          .lookupFunction<_JsonOneArgNative, _JsonOneArgDart>(
            'tt_core_set_app_exceptions',
          ),
      _setBridgeConfig = _library
          .lookupFunction<_JsonOneArgNative, _JsonOneArgDart>(
            'tt_core_set_bridge_config',
          ),
      _verifyExit = _library.lookupFunction<_JsonNoArgNative, _JsonNoArgDart>(
        'tt_core_verify_exit',
      ),
      _exportDiagnostics = _library
          .lookupFunction<_JsonNoArgNative, _JsonNoArgDart>(
            'tt_core_export_diagnostics',
          ),
      _runLeakSelfTest = _library
          .lookupFunction<_JsonNoArgNative, _JsonNoArgDart>(
            'tt_core_run_leak_self_test',
          ),
      _status = _library.lookupFunction<_JsonNoArgNative, _JsonNoArgDart>(
        'tt_core_status',
      );

  final DynamicLibrary _library;
  final _CreateDart _create;
  final _DestroyDart _destroy;
  final _FreeStringDart _freeString;
  final _JsonOneArgDart _connect;
  final _JsonNoArgDart _disconnect;
  final _JsonOneArgDart _startTor;
  final _JsonNoArgDart _stopTor;
  final _JsonNoArgDart _rotateIdentity;
  final _JsonOneArgDart _setAppExceptions;
  final _JsonOneArgDart _setBridgeConfig;
  final _JsonNoArgDart _verifyExit;
  final _JsonNoArgDart _exportDiagnostics;
  final _JsonNoArgDart _runLeakSelfTest;
  final _JsonNoArgDart _status;

  DynamicLibrary get library => _library;

  static TorTunnelFfiLibrary open() {
    if (Platform.isWindows) {
      return TorTunnelFfiLibrary._(DynamicLibrary.open('tor_tunnel_core.dll'));
    }
    if (Platform.isAndroid || Platform.isLinux) {
      return TorTunnelFfiLibrary._(
        DynamicLibrary.open('libtor_tunnel_core.so'),
      );
    }
    throw UnsupportedError(
      'TorTunnel core is only planned for Android, Linux, and Windows.',
    );
  }

  static TorTunnelFfiLibrary? tryOpen() {
    try {
      return open();
    } on Object {
      return null;
    }
  }

  /// Opens the native library from an explicit file [path]. Useful for tests
  /// and for desktop bundles that ship the cdylib next to the executable.
  factory TorTunnelFfiLibrary.fromPath(String path) =>
      TorTunnelFfiLibrary._(DynamicLibrary.open(path));

  FfiCoreSession createSession() => FfiCoreSession._(this, _create());
}

class FfiCoreSession {
  FfiCoreSession._(this._library, this._core);

  final TorTunnelFfiLibrary _library;
  final Pointer<Void> _core;
  bool _closed = false;

  Map<String, dynamic> connect(Map<String, dynamic> request) {
    return _callWithJson(_library._connect, request);
  }

  Map<String, dynamic> disconnect() => _callNoArg(_library._disconnect);

  Map<String, dynamic> startTor(Map<String, dynamic> bridgeConfig) {
    return _callWithJson(_library._startTor, bridgeConfig);
  }

  Map<String, dynamic> stopTor() => _callNoArg(_library._stopTor);

  Map<String, dynamic> rotateIdentity() => _callNoArg(_library._rotateIdentity);

  Map<String, dynamic> setAppExceptions(List<Map<String, dynamic>> exceptions) {
    return _callWithJson(_library._setAppExceptions, exceptions);
  }

  Map<String, dynamic> setBridgeConfig(Map<String, dynamic> bridgeConfig) {
    return _callWithJson(_library._setBridgeConfig, bridgeConfig);
  }

  Map<String, dynamic> verifyExit() => _callNoArg(_library._verifyExit);

  Map<String, dynamic> exportDiagnostics() =>
      _callNoArg(_library._exportDiagnostics);

  Map<String, dynamic> runLeakSelfTest() =>
      _callNoArg(_library._runLeakSelfTest);

  Map<String, dynamic> status() => _callNoArg(_library._status);

  void close() {
    if (_closed) {
      return;
    }
    _library._destroy(_core);
    _closed = true;
  }

  Map<String, dynamic> _callNoArg(_JsonNoArgDart call) {
    final response = call(_core);
    return _decodeAndFree(response);
  }

  Map<String, dynamic> _callWithJson(_JsonOneArgDart call, Object value) {
    final jsonPointer = jsonEncode(value).toNativeUtf8();
    try {
      final response = call(_core, jsonPointer);
      return _decodeAndFree(response);
    } finally {
      malloc.free(jsonPointer);
    }
  }

  Map<String, dynamic> _decodeAndFree(Pointer<Utf8> pointer) {
    try {
      final decoded = jsonDecode(pointer.toDartString());
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {
        'protocol_version': 1,
        'ok': false,
        'error': 'FFI response was not a JSON object.',
      };
    } finally {
      _library._freeString(pointer);
    }
  }
}

/// [CoreClient] backed by the real Rust core (`tor_tunnel_core`) over FFI.
///
/// Catalog data (profiles, relay countries) is presentation-only and stays on
/// the Dart side; every behavioural call (connect, rotate, verify, diagnostics,
/// leak self-test) is delegated to the native core and its JSON envelope is
/// mapped back onto the UI models. On desktop this surfaces the core's real
/// state machine and torrc generation while the native tunnel adapters are not
/// yet production-ready.
class FfiCoreClient extends CoreClient {
  FfiCoreClient._(this._session) {
    _refreshStatus(notify: false);
  }

  /// Opens the native library and creates a core session, or returns `null`
  /// when the library cannot be loaded (e.g. the cdylib was not built/bundled).
  static FfiCoreClient? tryOpen() {
    final library = TorTunnelFfiLibrary.tryOpen();
    if (library == null) {
      return null;
    }
    return FfiCoreClient._(library.createSession());
  }

  final FfiCoreSession _session;

  @override
  final List<CountryProfile> profiles = const [
    CountryProfile(
      id: 'eu-privacy',
      name: 'EU Privacy',
      exitCountries: ['DE', 'NL', 'SE'],
      description: 'Stable European exits with transparent fallback.',
    ),
    CountryProfile(
      id: 'north-atlantic',
      name: 'North Atlantic',
      exitCountries: ['US', 'CA', 'NL'],
      description: 'Good for broad compatibility with Tor exits.',
    ),
    CountryProfile(
      id: 'minimal-de',
      name: 'Germany Preferred',
      exitCountries: ['DE'],
      description: 'Single-country preference; may degrade more often.',
    ),
  ];

  @override
  final List<RelayCountryStatus> relayCountries = const [
    RelayCountryStatus(
      countryCode: 'DE',
      countryName: 'Germany',
      exitRelays: 168,
      available: true,
      stabilityScore: 94,
    ),
    RelayCountryStatus(
      countryCode: 'NL',
      countryName: 'Netherlands',
      exitRelays: 221,
      available: true,
      stabilityScore: 97,
    ),
    RelayCountryStatus(
      countryCode: 'SE',
      countryName: 'Sweden',
      exitRelays: 72,
      available: true,
      stabilityScore: 88,
    ),
    RelayCountryStatus(
      countryCode: 'IS',
      countryName: 'Iceland',
      exitRelays: 0,
      available: false,
      stabilityScore: 0,
    ),
  ];

  @override
  CountryProfile selectedProfile = const CountryProfile(
    id: 'eu-privacy',
    name: 'EU Privacy',
    exitCountries: ['DE', 'NL', 'SE'],
    description: 'Stable European exits with transparent fallback.',
  );

  @override
  ConnectionMode connectionMode = ConnectionMode.strict;
  @override
  BridgeConfig bridgeConfig = const BridgeConfig(
    kind: BridgeKind.none,
    label: 'No bridges',
  );
  @override
  ConnectionStatus status = ConnectionStatus.disconnected();
  @override
  ExitVerification? lastVerification;
  @override
  LeakSelfTestReport? lastLeakSelfTest;
  @override
  bool autoConnect = false;
  @override
  bool autoRotation = false;
  @override
  bool localVerboseDiagnostics = false;
  @override
  bool onboardingDismissed = false;

  @override
  List<AppException> appExceptions = const [
    AppException(
      appId: 'com.bank.mobile',
      displayName: 'Banking',
      enabled: false,
      reason: 'Some banking apps reject Tor exits.',
    ),
    AppException(
      appId: 'com.video.calls',
      displayName: 'Video Calls',
      enabled: false,
      reason: 'Realtime UDP traffic is blocked by TorTunnel MVP policy.',
    ),
    AppException(
      appId: 'org.package.manager',
      displayName: 'Package Manager',
      enabled: false,
      reason: 'Allowed outside tunnel during alpha for signed system updates.',
    ),
  ];

  @override
  Future<void> connect() async {
    final request = {
      'platform': _platformKebab(),
      'mode': _modeKebab(connectionMode),
      'profile': _profileJson(selectedProfile),
      'bridge_config': _bridgeJson(bridgeConfig),
      'app_exceptions': appExceptions.map(_exceptionJson).toList(),
      'auto_fallback': true,
      'isolate_by_app': true,
    };
    _session.connect(request);
    // The native core updates its internal status even on the strict-mode
    // rejection path, so always read it back rather than trusting the envelope.
    _refreshStatus();
  }

  @override
  void disconnect() {
    _session.disconnect();
    lastVerification = null;
    _refreshStatus();
  }

  @override
  Future<void> rotateIdentity() async {
    if (!status.isActive) {
      return;
    }
    _session.rotateIdentity();
    _refreshStatus();
  }

  @override
  void setSelectedProfile(CountryProfile profile) {
    selectedProfile = profile;
    notifyListeners();
  }

  @override
  void setConnectionMode(ConnectionMode mode) {
    connectionMode = mode;
    if (mode == ConnectionMode.strict) {
      appExceptions = [
        for (final exception in appExceptions)
          exception.copyWith(enabled: false),
      ];
      _session.setAppExceptions(appExceptions.map(_exceptionJson).toList());
    }
    notifyListeners();
  }

  @override
  void setBridgeConfig(BridgeConfig value) {
    bridgeConfig = value;
    _session.setBridgeConfig(_bridgeJson(value));
    _refreshStatus();
  }

  @override
  void setAutoConnect(bool value) {
    autoConnect = value;
    notifyListeners();
  }

  @override
  void setAutoRotation(bool value) {
    autoRotation = value;
    notifyListeners();
  }

  @override
  void setVerboseDiagnostics(bool value) {
    localVerboseDiagnostics = value;
    notifyListeners();
  }

  @override
  void dismissOnboarding() {
    onboardingDismissed = true;
    notifyListeners();
  }

  @override
  void toggleAppException(String appId, bool enabled) {
    if (connectionMode == ConnectionMode.strict && enabled) {
      status = status.copyWith(
        health: TunnelHealth.blockedByKillSwitch,
        message:
            'Strict Mode forbids app exceptions. Switch to Compatibility Mode first.',
      );
      notifyListeners();
      return;
    }
    appExceptions = [
      for (final exception in appExceptions)
        if (exception.appId == appId)
          exception.copyWith(enabled: enabled)
        else
          exception,
    ];
    _session.setAppExceptions(appExceptions.map(_exceptionJson).toList());
    notifyListeners();
  }

  @override
  ExitVerification verifyExit() {
    final payload = _payload(_session.verifyExit());
    lastVerification = payload == null
        ? const ExitVerification(
            isTor: false,
            observedIp: 'unknown',
            observedCountry: 'unknown',
            source: 'native-core',
            message: 'Not connected; no Tor exit can be verified.',
          )
        : ExitVerification(
            isTor: payload['is_tor'] as bool? ?? false,
            observedIp: payload['observed_ip'] as String? ?? 'unknown',
            observedCountry: payload['observed_country'] as String? ?? 'unknown',
            source: payload['source'] as String? ?? 'native-core',
            message: payload['message'] as String? ?? '',
          );
    notifyListeners();
    return lastVerification!;
  }

  @override
  String exportDiagnostics() {
    final payload = _payload(_session.exportDiagnostics());
    if (payload == null) {
      return 'Diagnostics unavailable from native core.';
    }
    final buffer = StringBuffer()
      ..writeln('TorTunnel diagnostics bundle (native core)')
      ..writeln('App version: ${payload['app_version']}')
      ..writeln('Platform: ${payload['platform'] ?? 'unknown'}')
      ..writeln('Health: ${payload['health']}')
      ..writeln('Telemetry: none')
      ..writeln('Upload: manual only');
    final torrc = payload['tor_config_preview'];
    if (torrc is String && torrc.isNotEmpty) {
      buffer
        ..writeln('--- torrc preview ---')
        ..writeln(torrc);
    }
    final blockers = (payload['release_blockers'] as List?) ?? const [];
    if (blockers.isNotEmpty) {
      buffer.writeln('Release blockers:');
      for (final blocker in blockers) {
        buffer.writeln('- $blocker');
      }
    }
    return buffer.toString().trimRight();
  }

  @override
  LeakSelfTestReport runLeakSelfTest() {
    final payload = _payload(_session.runLeakSelfTest());
    if (payload == null) {
      lastLeakSelfTest = const LeakSelfTestReport(
        strictMode: true,
        stableReleaseAllowed: false,
        results: [],
      );
    } else {
      final results = ((payload['results'] as List?) ?? const [])
          .map((entry) {
            final map = (entry as Map).cast<String, dynamic>();
            return LeakCheckResult(
              kind: (map['kind'] as String? ?? '').toUpperCase(),
              status: map['status'] as String? ?? '',
              message: map['message'] as String? ?? '',
            );
          })
          .toList();
      lastLeakSelfTest = LeakSelfTestReport(
        strictMode: payload['strict_mode'] as bool? ?? true,
        stableReleaseAllowed: payload['stable_release_allowed'] as bool? ?? false,
        results: results,
      );
    }
    notifyListeners();
    return lastLeakSelfTest!;
  }

  @override
  void dispose() {
    _session.close();
    super.dispose();
  }

  // --- Native bridge helpers -------------------------------------------------

  void _refreshStatus({bool notify = true}) {
    final payload = _payload(_session.status());
    if (payload != null) {
      status = _statusFromPayload(payload);
    }
    if (notify) {
      notifyListeners();
    }
  }

  Map<String, dynamic>? _payload(Map<String, dynamic> envelope) {
    if (envelope['ok'] == true && envelope['payload'] is Map) {
      return (envelope['payload'] as Map).cast<String, dynamic>();
    }
    return null;
  }

  ConnectionStatus _statusFromPayload(Map<String, dynamic> payload) {
    return ConnectionStatus(
      state: _parseState(payload['state'] as String?),
      mode: _parseMode(payload['mode'] as String?),
      health: _parseHealth(payload['health'] as String?),
      profile: selectedProfile,
      bridgeConfig: bridgeConfig,
      exitCountry: payload['exit_country'] as String?,
      exitIp: payload['exit_ip'] as String?,
      bootstrapPercent: (payload['bootstrap_percent'] as num?)?.toInt() ?? 0,
      killSwitchActive: payload['kill_switch_active'] as bool? ?? false,
      dnsProtected: payload['dns_protected'] as bool? ?? false,
      udpBlocked: payload['udp_blocked'] as bool? ?? true,
      ipv6Blocked: payload['ipv6_blocked'] as bool? ?? true,
      fallbackActive: payload['fallback_active'] as bool? ?? false,
      message: payload['message'] as String? ?? '',
      releaseBlockers: ((payload['release_blockers'] as List?) ?? const [])
          .map((entry) => entry.toString())
          .toList(),
    );
  }

  static String _platformKebab() {
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isWindows) {
      return 'windows';
    }
    return 'linux';
  }

  static String _modeKebab(ConnectionMode mode) {
    return mode == ConnectionMode.strict
        ? 'strict'
        : 'compatibility-reduced-protection';
  }

  static Map<String, dynamic> _profileJson(CountryProfile profile) {
    return {
      'id': profile.id,
      'name': profile.name,
      'exit_countries': profile.exitCountries,
      'preference_mode': 'prefer',
    };
  }

  static Map<String, dynamic> _exceptionJson(AppException exception) {
    return {
      'app_id': exception.appId,
      'display_name': exception.displayName,
      'enabled': exception.enabled,
      'reason': exception.reason,
    };
  }

  static Map<String, dynamic> _bridgeJson(BridgeConfig config) {
    switch (config.kind) {
      case BridgeKind.none:
        return {'kind': 'none'};
      case BridgeKind.manualObfs4:
        return {'kind': 'manual-obfs4', 'lines': config.lines};
      case BridgeKind.snowflake:
        return {'kind': 'snowflake'};
      case BridgeKind.customTransport:
        return {
          'kind': 'custom-transport',
          'name': config.label,
          'command': '',
          'args': <String>[],
        };
    }
  }

  static ConnectionStateKind _parseState(String? value) {
    switch (value) {
      case 'connecting':
        return ConnectionStateKind.connecting;
      case 'bootstrapping-tor':
        return ConnectionStateKind.bootstrappingTor;
      case 'connected':
        return ConnectionStateKind.connected;
      case 'degraded':
        return ConnectionStateKind.degraded;
      case 'fallback-active':
        return ConnectionStateKind.fallbackActive;
      case 'blocked-by-killswitch':
        return ConnectionStateKind.blockedByKillswitch;
      case 'error':
        return ConnectionStateKind.error;
      case 'disconnected':
      default:
        return ConnectionStateKind.disconnected;
    }
  }

  static TunnelHealth _parseHealth(String? value) {
    switch (value) {
      case 'protected':
        return TunnelHealth.protected;
      case 'reconnecting':
        return TunnelHealth.reconnecting;
      case 'fallback-country-active':
        return TunnelHealth.fallbackCountryActive;
      case 'reduced-protection':
        return TunnelHealth.reducedProtection;
      case 'error':
        return TunnelHealth.error;
      case 'blocked-by-kill-switch':
      default:
        return TunnelHealth.blockedByKillSwitch;
    }
  }

  static ConnectionMode _parseMode(String? value) {
    return value == 'compatibility-reduced-protection'
        ? ConnectionMode.compatibilityReducedProtection
        : ConnectionMode.strict;
  }
}

