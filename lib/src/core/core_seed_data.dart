import 'core_models.dart';

const seedProfiles = [
  CountryProfile(
    id: 'eu-privacy',
    name: 'EU Privacy',
    exitCountries: ['DE', 'NL', 'SE'],
    description:
        'Balanced European exit preference with room for transparent fallback.',
  ),
  CountryProfile(
    id: 'north-atlantic',
    name: 'North Atlantic',
    exitCountries: ['US', 'CA', 'NL'],
    description: 'Broad compatibility preference for Tor exits.',
  ),
  CountryProfile(
    id: 'minimal-de',
    name: 'Germany Preferred',
    exitCountries: ['DE'],
    description:
        'Single-country preference. Fallback may be limited and must stay visible.',
  ),
];

const seedRelayCountries = [
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

const seedAppExceptions = [
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

const defaultReleaseReadiness = ReleaseReadiness(
  platformReadiness: [
    PlatformReadiness(
      target: PlatformTarget.android,
      adapterName: 'Android VpnService',
      status: ReadinessStatus.notReady,
      evidenceId: 'adapter.android.vpnservice',
      message:
          'Packet loop, lockdown behavior, and device leak tests are pending.',
    ),
    PlatformReadiness(
      target: PlatformTarget.linux,
      adapterName: 'Linux TUN/nftables',
      status: ReadinessStatus.notReady,
      evidenceId: 'adapter.linux.tun-nftables',
      message:
          'Privileged helper and nftables default-deny rules are contract-only.',
    ),
    PlatformReadiness(
      target: PlatformTarget.windows,
      adapterName: 'Windows Wintun/WFP',
      status: ReadinessStatus.notReady,
      evidenceId: 'adapter.windows.wintun-wfp',
      message:
          'Wintun review, service signing, and WFP leak tests are pending.',
    ),
  ],
  steps: [
    ReadinessStep(
      id: 'native-adapter',
      title: 'Native adapter',
      status: ReadinessStatus.notReady,
      evidenceId: 'gate.native-adapter',
      detail: 'No platform adapter can claim real protection yet.',
    ),
    ReadinessStep(
      id: 'leak-tests',
      title: 'Leak tests',
      status: ReadinessStatus.notReady,
      evidenceId: 'gate.leak-tests',
      detail: 'Exit IP, DNS, UDP, IPv6, and kill-switch tests must pass.',
    ),
    ReadinessStep(
      id: 'release-audit',
      title: 'Release audit',
      status: ReadinessStatus.notReady,
      evidenceId: 'gate.release-audit',
      detail: 'Signing, Wintun review, packaging, and external audit are open.',
    ),
  ],
  evidence: [
    LeakEvidenceItem(
      id: 'leak.exit-ip',
      area: 'Exit IP',
      status: EvidenceStatus.blocked,
      evidenceId: 'docs/LEAK_TEST_MATRIX.md#exit-ip',
      message: 'Public IP must be a Tor exit after connect.',
    ),
    LeakEvidenceItem(
      id: 'leak.dns',
      area: 'DNS',
      status: EvidenceStatus.blocked,
      evidenceId: 'docs/LEAK_TEST_MATRIX.md#dns',
      message: 'System resolver bypass is not yet device-verified.',
    ),
    LeakEvidenceItem(
      id: 'leak.ipv6',
      area: 'IPv6',
      status: EvidenceStatus.blocked,
      evidenceId: 'docs/LEAK_TEST_MATRIX.md#ipv6',
      message: 'IPv6 remains blocked in the MVP.',
    ),
    LeakEvidenceItem(
      id: 'leak.udp',
      area: 'UDP',
      status: EvidenceStatus.blocked,
      evidenceId: 'docs/LEAK_TEST_MATRIX.md#udp',
      message: 'UDP must not bypass TorTunnel.',
    ),
    LeakEvidenceItem(
      id: 'leak.kill-switch',
      area: 'Kill-switch',
      status: EvidenceStatus.blocked,
      evidenceId: 'docs/LEAK_TEST_MATRIX.md#kill-switch',
      message: 'Traffic must stay blocked during Tor failure.',
    ),
    LeakEvidenceItem(
      id: 'leak.network-change',
      area: 'Network change',
      status: EvidenceStatus.pending,
      evidenceId: 'docs/LEAK_TEST_MATRIX.md#network-change',
      message: 'Reconnect behavior needs device and VM coverage.',
    ),
    LeakEvidenceItem(
      id: 'leak.sleep-resume',
      area: 'Sleep/resume',
      status: EvidenceStatus.pending,
      evidenceId: 'docs/LEAK_TEST_MATRIX.md#sleep-resume',
      message: 'Kill-switch persistence after resume is not verified.',
    ),
    LeakEvidenceItem(
      id: 'leak.diagnostics',
      area: 'Diagnostics',
      status: EvidenceStatus.localOnly,
      evidenceId: 'docs/THREAT_MODEL.md#goals',
      message: 'Diagnostics remain local and manually exported.',
    ),
  ],
);

const defaultProtectionClaims = [
  ProtectionClaim(
    label: 'No accounts',
    status: EvidenceStatus.localOnly,
    evidenceId: 'README.md#important-status',
    message: 'There is no backend account system in this repository.',
  ),
  ProtectionClaim(
    label: 'Local diagnostics only',
    status: EvidenceStatus.localOnly,
    evidenceId: 'docs/THREAT_MODEL.md#goals',
    message: 'Diagnostic bundles are manually exported by the user.',
  ),
  ProtectionClaim(
    label: 'Strict Mode protection',
    status: EvidenceStatus.blocked,
    evidenceId: 'docs/audit/STABLE_BLOCKERS.md',
    message: 'Strict Mode cannot claim protected until native adapters pass.',
  ),
  ProtectionClaim(
    label: 'Exit country',
    status: EvidenceStatus.pending,
    evidenceId: 'docs/THREAT_MODEL.md#required-mitigations',
    message: 'Exit countries are preferences, not guarantees.',
  ),
];
