enum LanguageChoice { de, en }

enum PlatformTarget { android, linux, windows }

enum ConnectionMode { strict, compatibilityReducedProtection }

enum TunnelHealth {
  protected,
  reconnecting,
  fallbackCountryActive,
  reducedProtection,
  blockedByKillSwitch,
  error,
}

enum BridgeKind { none, manualObfs4, snowflake, customTransport }

enum ConnectionStateKind {
  disconnected,
  connecting,
  bootstrappingTor,
  connected,
  degraded,
  fallbackActive,
  blockedByKillswitch,
  error,
}

class CountryProfile {
  const CountryProfile({
    required this.id,
    required this.name,
    required this.exitCountries,
    required this.description,
  });

  final String id;
  final String name;
  final List<String> exitCountries;
  final String description;
}

class RelayCountryStatus {
  const RelayCountryStatus({
    required this.countryCode,
    required this.countryName,
    required this.exitRelays,
    required this.available,
    required this.stabilityScore,
  });

  final String countryCode;
  final String countryName;
  final int exitRelays;
  final bool available;
  final int stabilityScore;
}

class AppException {
  const AppException({
    required this.appId,
    required this.displayName,
    required this.enabled,
    required this.reason,
  });

  final String appId;
  final String displayName;
  final bool enabled;
  final String reason;

  AppException copyWith({bool? enabled}) {
    return AppException(
      appId: appId,
      displayName: displayName,
      enabled: enabled ?? this.enabled,
      reason: reason,
    );
  }
}

class BridgeConfig {
  const BridgeConfig({
    required this.kind,
    required this.label,
    this.lines = const [],
  });

  final BridgeKind kind;
  final String label;
  final List<String> lines;
}

class ConnectionStatus {
  const ConnectionStatus({
    required this.state,
    required this.mode,
    required this.health,
    required this.bootstrapPercent,
    required this.killSwitchActive,
    required this.dnsProtected,
    required this.udpBlocked,
    required this.ipv6Blocked,
    required this.fallbackActive,
    required this.message,
    required this.releaseBlockers,
    this.profile,
    this.bridgeConfig,
    this.exitCountry,
    this.exitIp,
  });

  factory ConnectionStatus.disconnected() {
    return const ConnectionStatus(
      state: ConnectionStateKind.disconnected,
      mode: ConnectionMode.strict,
      health: TunnelHealth.blockedByKillSwitch,
      bootstrapPercent: 0,
      killSwitchActive: false,
      dnsProtected: false,
      udpBlocked: true,
      ipv6Blocked: true,
      fallbackActive: false,
      message: 'Disconnected',
      releaseBlockers: [],
    );
  }

  final ConnectionStateKind state;
  final ConnectionMode mode;
  final TunnelHealth health;
  final CountryProfile? profile;
  final BridgeConfig? bridgeConfig;
  final String? exitCountry;
  final String? exitIp;
  final int bootstrapPercent;
  final bool killSwitchActive;
  final bool dnsProtected;
  final bool udpBlocked;
  final bool ipv6Blocked;
  final bool fallbackActive;
  final String message;
  final List<String> releaseBlockers;

  bool get isActive =>
      state == ConnectionStateKind.connected ||
      state == ConnectionStateKind.degraded ||
      state == ConnectionStateKind.fallbackActive;

  ConnectionStatus copyWith({
    ConnectionStateKind? state,
    ConnectionMode? mode,
    TunnelHealth? health,
    CountryProfile? profile,
    BridgeConfig? bridgeConfig,
    String? exitCountry,
    String? exitIp,
    int? bootstrapPercent,
    bool? killSwitchActive,
    bool? dnsProtected,
    bool? udpBlocked,
    bool? ipv6Blocked,
    bool? fallbackActive,
    String? message,
    List<String>? releaseBlockers,
  }) {
    return ConnectionStatus(
      state: state ?? this.state,
      mode: mode ?? this.mode,
      health: health ?? this.health,
      profile: profile ?? this.profile,
      bridgeConfig: bridgeConfig ?? this.bridgeConfig,
      exitCountry: exitCountry ?? this.exitCountry,
      exitIp: exitIp ?? this.exitIp,
      bootstrapPercent: bootstrapPercent ?? this.bootstrapPercent,
      killSwitchActive: killSwitchActive ?? this.killSwitchActive,
      dnsProtected: dnsProtected ?? this.dnsProtected,
      udpBlocked: udpBlocked ?? this.udpBlocked,
      ipv6Blocked: ipv6Blocked ?? this.ipv6Blocked,
      fallbackActive: fallbackActive ?? this.fallbackActive,
      message: message ?? this.message,
      releaseBlockers: releaseBlockers ?? this.releaseBlockers,
    );
  }
}

class ExitVerification {
  const ExitVerification({
    required this.isTor,
    required this.observedIp,
    required this.observedCountry,
    required this.source,
    required this.message,
  });

  final bool isTor;
  final String observedIp;
  final String observedCountry;
  final String source;
  final String message;
}

class LeakCheckResult {
  const LeakCheckResult({
    required this.kind,
    required this.status,
    required this.message,
  });

  final String kind;
  final String status;
  final String message;
}

class LeakSelfTestReport {
  const LeakSelfTestReport({
    required this.strictMode,
    required this.stableReleaseAllowed,
    required this.results,
  });

  final bool strictMode;
  final bool stableReleaseAllowed;
  final List<LeakCheckResult> results;
}
