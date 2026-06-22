import 'core_client.dart';
import 'core_models.dart';

/// Pure-Dart development core. Mirrors the Rust core surface so the UI is fully
/// usable when the native `tor_tunnel_core` library is unavailable. It never
/// claims `protected`: it deliberately surfaces release blockers instead.
class MockCoreClient extends CoreClient {
  MockCoreClient();

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
    final enabledExceptions = appExceptions
        .where((exception) => exception.enabled)
        .toList();
    if (connectionMode == ConnectionMode.strict &&
        enabledExceptions.isNotEmpty) {
      status = ConnectionStatus(
        state: ConnectionStateKind.blockedByKillswitch,
        mode: connectionMode,
        health: TunnelHealth.blockedByKillSwitch,
        profile: selectedProfile,
        bridgeConfig: bridgeConfig,
        bootstrapPercent: 0,
        killSwitchActive: true,
        dnsProtected: true,
        udpBlocked: true,
        ipv6Blocked: true,
        fallbackActive: false,
        message:
            'Strict Mode blocks app exceptions. Disable exceptions or switch to Compatibility Mode.',
        releaseBlockers: const [
          'Strict Mode cannot run with enabled app exceptions.',
        ],
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
      bootstrapPercent: 18,
      killSwitchActive: true,
      dnsProtected: true,
      udpBlocked: true,
      ipv6Blocked: true,
      fallbackActive: false,
      message: 'Starting Tor daemon and applying kill-switch policy.',
      releaseBlockers: const [
        'Native tunnel adapters are not production-ready.',
        'External audit is not complete.',
      ],
    );
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 450));

    status = status.copyWith(
      state: ConnectionStateKind.bootstrappingTor,
      bootstrapPercent: 72,
      message: 'Bootstrapping Tor circuits and resolving exit preferences.',
    );
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 450));

    status = status.copyWith(
      state: connectionMode == ConnectionMode.strict
          ? ConnectionStateKind.blockedByKillswitch
          : ConnectionStateKind.degraded,
      health: connectionMode == ConnectionMode.strict
          ? TunnelHealth.blockedByKillSwitch
          : TunnelHealth.reducedProtection,
      bootstrapPercent: 100,
      exitCountry: selectedProfile.exitCountries.first,
      exitIp: '185.220.101.42',
      message: connectionMode == ConnectionMode.strict
          ? 'Strict Mode is blocked until native adapters are production-ready.'
          : 'Compatibility Mode development core active. Protection is reduced and not stable-ready.',
      releaseBlockers: const [
        'Android/Linux/Windows native adapters must pass leak tests.',
        'Tor, obfs4proxy and Snowflake reproducible bundles are not wired.',
        'External audit is not complete.',
      ],
    );
    lastVerification = const ExitVerification(
      isTor: true,
      observedIp: '185.220.101.42',
      observedCountry: 'DE',
      source: 'mock-public-check',
      message:
          'Public exit verification contract is ready; network call is mocked.',
    );
    notifyListeners();
  }

  @override
  void disconnect() {
    status = ConnectionStatus.disconnected();
    lastVerification = null;
    notifyListeners();
  }

  @override
  Future<void> rotateIdentity() async {
    if (!status.isActive) {
      return;
    }
    status = status.copyWith(
      message: 'Requesting NEWNYM through Tor ControlPort.',
    );
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    status = status.copyWith(
      exitIp: '193.189.100.207',
      message:
          'New identity requested. Circuits and exit observation refreshed.',
    );
    lastVerification = const ExitVerification(
      isTor: true,
      observedIp: '193.189.100.207',
      observedCountry: 'NL',
      source: 'mock-public-check',
      message: 'Observed exit changed after identity rotation.',
    );
    notifyListeners();
  }

  @override
  void setSelectedProfile(CountryProfile profile) {
    selectedProfile = profile;
    if (status.isActive) {
      status = status.copyWith(
        profile: profile,
        fallbackActive: profile.exitCountries.length == 1,
        message: profile.exitCountries.length == 1
            ? 'Single-country profile selected; fallback room is limited.'
            : 'Country preference updated. Tor will prefer this profile on reconnect.',
      );
    }
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
      status = status.copyWith(
        mode: mode,
        health: TunnelHealth.blockedByKillSwitch,
        message:
            'Strict Mode selected. App exceptions are disabled and direct fallback is blocked.',
      );
    } else {
      status = status.copyWith(
        mode: mode,
        health: TunnelHealth.reducedProtection,
        message:
            'Compatibility Mode selected. App exceptions can reduce privacy.',
      );
    }
    notifyListeners();
  }

  @override
  void setBridgeConfig(BridgeConfig value) {
    bridgeConfig = value;
    status = status.copyWith(
      bridgeConfig: value,
      message: 'Bridge configuration changed. Reconnect to apply it.',
    );
    notifyListeners();
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
    notifyListeners();
  }

  @override
  ExitVerification verifyExit() {
    lastVerification = ExitVerification(
      isTor: status.isActive,
      observedIp: status.exitIp ?? 'unknown',
      observedCountry: status.exitCountry ?? 'unknown',
      source: 'mock-public-check',
      message: status.isActive
          ? 'Tor exit verified through the public-check contract.'
          : 'Not connected; no Tor exit can be verified.',
    );
    notifyListeners();
    return lastVerification!;
  }

  @override
  String exportDiagnostics() {
    final exceptions = appExceptions
        .where((exception) => exception.enabled)
        .map((exception) => exception.displayName)
        .join(', ');
    return [
      'TorTunnel diagnostics bundle',
      'State: ${status.state.name}',
      'Mode: ${connectionMode.name}',
      'Health: ${status.health.name}',
      'Profile: ${selectedProfile.name}',
      'Bridge: ${bridgeConfig.label}',
      'Exit countries: ${selectedProfile.exitCountries.join(', ')}',
      'Kill switch: ${status.killSwitchActive}',
      'DNS protected: ${status.dnsProtected}',
      'UDP blocked: ${status.udpBlocked}',
      'IPv6 blocked: ${status.ipv6Blocked}',
      'Enabled app exceptions: ${exceptions.isEmpty ? 'none' : exceptions}',
      'Telemetry: none',
      'Upload: manual only',
    ].join('\n');
  }

  @override
  LeakSelfTestReport runLeakSelfTest() {
    lastLeakSelfTest = const LeakSelfTestReport(
      strictMode: true,
      stableReleaseAllowed: false,
      results: [
        LeakCheckResult(
          kind: 'IP',
          status: 'blocked',
          message:
              'Native adapter is not production-ready; external IP test cannot pass.',
        ),
        LeakCheckResult(
          kind: 'DNS',
          status: 'blocked',
          message:
              'DNS policy is contract-only until platform helpers are implemented.',
        ),
        LeakCheckResult(
          kind: 'UDP',
          status: 'blocked',
          message:
              'UDP block contract exists; device-level verification is pending.',
        ),
        LeakCheckResult(
          kind: 'IPv6',
          status: 'blocked',
          message: 'IPv6 remains disabled pending separate audit.',
        ),
        LeakCheckResult(
          kind: 'Kill switch',
          status: 'blocked',
          message: 'Kill-switch requires native adapter verification.',
        ),
      ],
    );
    notifyListeners();
    return lastLeakSelfTest!;
  }
}
