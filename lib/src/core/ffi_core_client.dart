import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'core_client.dart';
import 'core_models.dart';
import 'core_seed_data.dart';

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
      _releaseReadiness = _library
          .lookupFunction<_JsonNoArgNative, _JsonNoArgDart>(
            'tt_core_release_readiness',
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
  final _JsonNoArgDart _releaseReadiness;
  final _JsonNoArgDart _status;

  DynamicLibrary get library => _library;

  static TorTunnelFfiLibrary open() {
    final path = _bundledLibraryPath();
    if (path != null) {
      return TorTunnelFfiLibrary._(DynamicLibrary.open(path));
    }
    throw UnsupportedError(
      'TorTunnel core library was not found in the application bundle.',
    );
  }

  static String? _bundledLibraryPath() {
    if (Platform.isWindows) {
      final candidate = File(
        '${File(Platform.resolvedExecutable).parent.path}'
        '${Platform.pathSeparator}tor_tunnel_core.dll',
      );
      return candidate.existsSync() ? candidate.path : null;
    }
    if (Platform.isAndroid || Platform.isLinux) {
      if (Platform.isAndroid) {
        final candidate = File(
          '/data/data/org.tortunnel.tortunnel/lib/libtor_tunnel_core.so',
        );
        if (candidate.existsSync()) {
          return candidate.path;
        }
      }
      final executableDir = File(Platform.resolvedExecutable).parent;
      final candidates = [
        File(
          '${executableDir.path}${Platform.pathSeparator}libtor_tunnel_core.so',
        ),
        File(
          '${executableDir.path}${Platform.pathSeparator}lib${Platform.pathSeparator}libtor_tunnel_core.so',
        ),
      ];
      for (final candidate in candidates) {
        if (candidate.existsSync()) {
          return candidate.path;
        }
      }
      return null;
    }
    return null;
  }

  static TorTunnelFfiLibrary? tryOpen() {
    try {
      return open();
    } on Object {
      return null;
    }
  }

  FfiCoreSession createSession() => FfiCoreSession._(this, _create());
}

class FfiCoreClient extends CoreClient {
  FfiCoreClient._(this._session);

  final FfiCoreSession _session;

  static FfiCoreClient? tryCreate() {
    final library = TorTunnelFfiLibrary.tryOpen();
    if (library == null) {
      return null;
    }
    return FfiCoreClient._(library.createSession());
  }

  @override
  final List<CountryProfile> profiles = seedProfiles;

  @override
  final List<RelayCountryStatus> relayCountries = seedRelayCountries;

  @override
  CountryProfile selectedProfile = seedProfiles.first;

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
  ReleaseReadiness releaseReadiness = defaultReleaseReadiness;

  @override
  List<ProtectionClaim> protectionClaims = defaultProtectionClaims;

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
  List<AppException> appExceptions = seedAppExceptions;

  @override
  Future<void> connect() async {
    if (!releaseReadiness.canAttemptRealConnection) {
      status = ConnectionStatus(
        state: ConnectionStateKind.blockedByKillswitch,
        mode: connectionMode,
        health: TunnelHealth.blockedByKillSwitch,
        profile: selectedProfile,
        bridgeConfig: bridgeConfig,
        bootstrapPercent: 0,
        killSwitchActive: true,
        dnsProtected: false,
        udpBlocked: false,
        ipv6Blocked: false,
        fallbackActive: false,
        message:
            'Connect is locked because platform adapter evidence is incomplete.',
        releaseBlockers: const [
          'Native adapter evidence is incomplete.',
          'Leak-test matrix has not passed.',
          'External audit is not complete.',
        ],
      );
      notifyListeners();
      return;
    }

    final response = _session.connect({
      'platform': _platformForHost(),
      'mode': _modeToJson(connectionMode),
      'profile': _profileToJson(selectedProfile),
      'bridge_config': _bridgeToJson(bridgeConfig),
      'app_exceptions': appExceptions.map(_exceptionToJson).toList(),
      'auto_fallback': true,
      'isolate_by_app': true,
    });
    _applyStatusEnvelope(response);
  }

  @override
  void disconnect() {
    _applyStatusEnvelope(_session.disconnect());
    lastVerification = null;
  }

  @override
  Future<void> rotateIdentity() async {
    _applyStatusEnvelope(_session.rotateIdentity());
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
    }
    status = status.copyWith(
      mode: mode,
      health: mode == ConnectionMode.strict
          ? TunnelHealth.blockedByKillSwitch
          : TunnelHealth.reducedProtection,
      message: mode == ConnectionMode.strict
          ? 'Strict Mode selected. App exceptions are disabled.'
          : 'Compatibility Mode selected. Protection is reduced.',
    );
    notifyListeners();
  }

  @override
  void setBridgeConfig(BridgeConfig value) {
    bridgeConfig = value;
    _applyStatusEnvelope(_session.setBridgeConfig(_bridgeToJson(value)));
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
        message: 'Strict Mode forbids app exceptions.',
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
    _session.setAppExceptions(appExceptions.map(_exceptionToJson).toList());
    notifyListeners();
  }

  @override
  ExitVerification verifyExit() {
    final response = _session.verifyExit();
    final payload = response['payload'];
    if (response['ok'] == true && payload is Map<String, dynamic>) {
      lastVerification = ExitVerification(
        isTor: payload['is_tor'] == true,
        observedIp: payload['observed_ip']?.toString() ?? 'unknown',
        observedCountry: payload['observed_country']?.toString() ?? 'unknown',
        source: payload['source']?.toString() ?? 'ffi',
        message: payload['message']?.toString() ?? 'Exit check returned.',
      );
    } else {
      lastVerification = ExitVerification(
        isTor: false,
        observedIp: 'unknown',
        observedCountry: 'unknown',
        source: 'ffi',
        message:
            response['error']?.toString() ??
            'Setup is not ready for exit verification.',
      );
    }
    notifyListeners();
    return lastVerification!;
  }

  @override
  String exportDiagnostics() {
    final response = _session.exportDiagnostics();
    final payload = response['payload'];
    if (response['ok'] == true && payload != null) {
      return const JsonEncoder.withIndent('  ').convert(payload);
    }
    return [
      'TorTunnel diagnostics bundle',
      'Source: ffi',
      'Error: ${response['error'] ?? 'unknown'}',
      'Upload: manual only',
    ].join('\n');
  }

  @override
  LeakSelfTestReport runLeakSelfTest() {
    final response = _session.runLeakSelfTest();
    final payload = response['payload'];
    if (response['ok'] == true && payload is Map<String, dynamic>) {
      lastLeakSelfTest = LeakSelfTestReport(
        strictMode: payload['strict_mode'] == true,
        stableReleaseAllowed: payload['stable_release_allowed'] == true,
        results: [
          for (final item in (payload['results'] as List<dynamic>? ?? []))
            if (item is Map<String, dynamic>)
              LeakCheckResult(
                kind: item['kind']?.toString() ?? 'unknown',
                status: item['status']?.toString() ?? 'unknown',
                message: item['message']?.toString() ?? '',
              ),
        ],
      );
    } else {
      lastLeakSelfTest = const LeakSelfTestReport(
        strictMode: true,
        stableReleaseAllowed: false,
        results: [
          LeakCheckResult(
            kind: 'preflight',
            status: 'blocked',
            message: 'FFI leak self-test did not return a valid report.',
          ),
        ],
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

  void _applyStatusEnvelope(Map<String, dynamic> response) {
    final payload = response['payload'];
    if (response['ok'] == true && payload is Map<String, dynamic>) {
      status = _statusFromJson(payload);
    } else {
      status = status.copyWith(
        state: ConnectionStateKind.error,
        health: TunnelHealth.error,
        message: response['error']?.toString() ?? 'Core request failed.',
      );
    }
    notifyListeners();
  }

  ConnectionStatus _statusFromJson(Map<String, dynamic> value) {
    return ConnectionStatus(
      state: _connectionState(value['state']?.toString()),
      mode: _connectionMode(value['mode']?.toString()),
      health: _tunnelHealth(value['health']?.toString()),
      profile: selectedProfile,
      bridgeConfig: bridgeConfig,
      exitCountry: value['exit_country']?.toString(),
      exitIp: value['exit_ip']?.toString(),
      bootstrapPercent: (value['bootstrap_percent'] as num?)?.round() ?? 0,
      killSwitchActive: value['kill_switch_active'] == true,
      dnsProtected: value['dns_protected'] == true,
      udpBlocked: value['udp_blocked'] == true,
      ipv6Blocked: value['ipv6_blocked'] == true,
      fallbackActive: value['fallback_active'] == true,
      message: value['message']?.toString() ?? 'Core status updated.',
      releaseBlockers: [
        for (final blocker
            in (value['release_blockers'] as List<dynamic>? ?? []))
          blocker.toString(),
      ],
    );
  }

  String _platformForHost() {
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isLinux) {
      return 'linux';
    }
    if (Platform.isWindows) {
      return 'windows';
    }
    return 'linux';
  }

  String _modeToJson(ConnectionMode mode) {
    return mode == ConnectionMode.strict
        ? 'strict'
        : 'compatibility-reduced-protection';
  }

  Map<String, dynamic> _profileToJson(CountryProfile profile) {
    return {
      'id': profile.id,
      'name': profile.name,
      'exit_countries': profile.exitCountries,
      'preference_mode': 'prefer',
    };
  }

  Map<String, dynamic> _bridgeToJson(BridgeConfig config) {
    return switch (config.kind) {
      BridgeKind.none => {'kind': 'none'},
      BridgeKind.manualObfs4 => {'kind': 'manual-obfs4', 'lines': config.lines},
      BridgeKind.snowflake => {'kind': 'snowflake'},
      BridgeKind.customTransport => {
        'kind': 'custom-transport',
        'name': config.label,
        'command': config.label,
        'args': config.lines,
      },
    };
  }

  Map<String, dynamic> _exceptionToJson(AppException exception) {
    return {
      'app_id': exception.appId,
      'display_name': exception.displayName,
      'enabled': exception.enabled,
      'reason': exception.reason,
    };
  }

  ConnectionStateKind _connectionState(String? value) {
    return switch (value) {
      'connecting' => ConnectionStateKind.connecting,
      'bootstrapping-tor' => ConnectionStateKind.bootstrappingTor,
      'connected' => ConnectionStateKind.connected,
      'degraded' => ConnectionStateKind.degraded,
      'fallback-active' => ConnectionStateKind.fallbackActive,
      'blocked-by-killswitch' => ConnectionStateKind.blockedByKillswitch,
      'error' => ConnectionStateKind.error,
      _ => ConnectionStateKind.disconnected,
    };
  }

  ConnectionMode _connectionMode(String? value) {
    return value == 'compatibility-reduced-protection'
        ? ConnectionMode.compatibilityReducedProtection
        : ConnectionMode.strict;
  }

  TunnelHealth _tunnelHealth(String? value) {
    return switch (value) {
      'protected' => TunnelHealth.protected,
      'reconnecting' => TunnelHealth.reconnecting,
      'fallback-country-active' => TunnelHealth.fallbackCountryActive,
      'reduced-protection' => TunnelHealth.reducedProtection,
      'error' => TunnelHealth.error,
      _ => TunnelHealth.blockedByKillSwitch,
    };
  }
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

  Map<String, dynamic> releaseReadiness() =>
      _callNoArg(_library._releaseReadiness);

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
      if (decoded is Map<String, dynamic> &&
          decoded['protocol_version'] == 1 &&
          decoded['ok'] is bool) {
        return decoded;
      }
      return {
        'protocol_version': 1,
        'ok': false,
        'error': 'FFI response envelope was invalid or unsupported.',
      };
    } finally {
      _library._freeString(pointer);
    }
  }
}
