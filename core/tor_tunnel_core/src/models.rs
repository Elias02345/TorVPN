use serde::{Deserialize, Serialize};
pub use tor_tunnel_diagnostics::DiagnosticBundle;
pub use tor_tunnel_leaktest::{
    LeakCheckKind, LeakCheckResult, LeakCheckStatus, LeakSelfTestReport,
};
pub use tor_tunnel_platform_contracts::{Platform, PlatformCapabilities, SignedComponentStatus};
pub use tor_tunnel_tor_manager::BridgeConfig;

pub const FFI_PROTOCOL_VERSION: u32 = 1;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum CountryPreferenceMode {
    Prefer,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ConnectionMode {
    Strict,
    CompatibilityReducedProtection,
}

impl Default for ConnectionMode {
    fn default() -> Self {
        Self::Strict
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum TunnelHealth {
    Protected,
    Reconnecting,
    FallbackCountryActive,
    ReducedProtection,
    BlockedByKillSwitch,
    Error,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ReadinessStatus {
    Verified,
    Pending,
    NotReady,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum EvidenceStatus {
    Verified,
    Pending,
    Blocked,
    LocalOnly,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CountryProfile {
    pub id: String,
    pub name: String,
    pub exit_countries: Vec<String>,
    pub preference_mode: CountryPreferenceMode,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AppException {
    pub app_id: String,
    pub display_name: String,
    pub enabled: bool,
    pub reason: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ConnectionRequest {
    pub platform: Platform,
    pub mode: ConnectionMode,
    pub profile: CountryProfile,
    pub bridge_config: BridgeConfig,
    pub app_exceptions: Vec<AppException>,
    pub auto_fallback: bool,
    pub isolate_by_app: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ConnectionState {
    Disconnected,
    Connecting,
    BootstrappingTor,
    Connected,
    Degraded,
    FallbackActive,
    BlockedByKillswitch,
    Error,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ConnectionStatus {
    pub state: ConnectionState,
    pub health: TunnelHealth,
    pub mode: ConnectionMode,
    pub platform: Option<Platform>,
    pub profile: Option<CountryProfile>,
    pub bridge_config: BridgeConfig,
    pub exit_country: Option<String>,
    pub exit_ip: Option<String>,
    pub bootstrap_percent: u8,
    pub kill_switch_active: bool,
    pub dns_protected: bool,
    pub udp_blocked: bool,
    pub ipv6_blocked: bool,
    pub fallback_active: bool,
    pub message: String,
    pub release_blockers: Vec<String>,
    pub updated_at_unix: u64,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PlatformReadiness {
    pub platform: Platform,
    pub adapter_name: String,
    pub status: ReadinessStatus,
    pub evidence_id: String,
    pub message: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ReadinessStep {
    pub id: String,
    pub title: String,
    pub status: ReadinessStatus,
    pub evidence_id: String,
    pub detail: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LeakEvidenceItem {
    pub id: String,
    pub area: String,
    pub status: EvidenceStatus,
    pub evidence_id: String,
    pub message: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ProtectionClaim {
    pub label: String,
    pub status: EvidenceStatus,
    pub evidence_id: String,
    pub message: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ReleaseReadiness {
    pub platform_readiness: Vec<PlatformReadiness>,
    pub steps: Vec<ReadinessStep>,
    pub evidence: Vec<LeakEvidenceItem>,
    pub claims: Vec<ProtectionClaim>,
}

impl ConnectionStatus {
    pub fn disconnected() -> Self {
        Self {
            state: ConnectionState::Disconnected,
            health: TunnelHealth::BlockedByKillSwitch,
            mode: ConnectionMode::Strict,
            platform: None,
            profile: None,
            bridge_config: BridgeConfig::None,
            exit_country: None,
            exit_ip: None,
            bootstrap_percent: 0,
            kill_switch_active: false,
            dns_protected: false,
            udp_blocked: false,
            ipv6_blocked: false,
            fallback_active: false,
            message: "Disconnected. No traffic is routed through TorTunnel.".to_string(),
            release_blockers: Vec::new(),
            updated_at_unix: 0,
        }
    }

    pub fn connecting(
        platform: Platform,
        mode: ConnectionMode,
        bridge_config: BridgeConfig,
    ) -> Self {
        Self {
            state: ConnectionState::Connecting,
            health: TunnelHealth::Reconnecting,
            mode,
            platform: Some(platform),
            profile: None,
            bridge_config,
            exit_country: None,
            exit_ip: None,
            bootstrap_percent: 10,
            kill_switch_active: true,
            dns_protected: false,
            udp_blocked: false,
            ipv6_blocked: false,
            fallback_active: false,
            message: "Starting Tor and enabling leak protection.".to_string(),
            release_blockers: Vec::new(),
            updated_at_unix: 0,
        }
    }

    pub fn degraded(
        platform: Platform,
        mode: ConnectionMode,
        bridge_config: BridgeConfig,
        message: &str,
        release_blockers: Vec<String>,
    ) -> Self {
        Self {
            state: ConnectionState::Degraded,
            health: if mode == ConnectionMode::Strict {
                TunnelHealth::BlockedByKillSwitch
            } else {
                TunnelHealth::ReducedProtection
            },
            mode,
            platform: Some(platform),
            profile: None,
            bridge_config,
            exit_country: None,
            exit_ip: None,
            bootstrap_percent: 0,
            kill_switch_active: true,
            dns_protected: false,
            udp_blocked: false,
            ipv6_blocked: false,
            fallback_active: false,
            message: message.to_string(),
            release_blockers,
            updated_at_unix: 0,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RelayCountryStatus {
    pub country_code: String,
    pub country_name: String,
    pub exit_relays: u32,
    pub available: bool,
    pub stability_score: u8,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ExitVerification {
    pub checked_at_unix: u64,
    pub is_tor: bool,
    pub observed_ip: String,
    pub observed_country: String,
    pub source: String,
    pub message: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct FfiEnvelope<T> {
    pub protocol_version: u32,
    pub ok: bool,
    pub payload: Option<T>,
    pub error: Option<String>,
}

impl<T> FfiEnvelope<T> {
    pub fn ok(payload: T) -> Self {
        Self {
            protocol_version: FFI_PROTOCOL_VERSION,
            ok: true,
            payload: Some(payload),
            error: None,
        }
    }

    pub fn error(message: impl Into<String>) -> Self {
        Self {
            protocol_version: FFI_PROTOCOL_VERSION,
            ok: false,
            payload: None,
            error: Some(message.into()),
        }
    }
}
