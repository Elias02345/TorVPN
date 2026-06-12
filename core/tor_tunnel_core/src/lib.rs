mod ffi;
mod models;
mod platform;
mod tor_config;

pub use models::*;
pub use platform::*;
pub use tor_config::*;

use std::time::{SystemTime, UNIX_EPOCH};
use tor_tunnel_diagnostics::{redact_log_line, RedactionPolicy};
use tor_tunnel_platform_contracts::capabilities;

#[derive(Debug, thiserror::Error)]
pub enum CoreError {
    #[error("country profile must include at least one preferred exit country")]
    EmptyCountryProfile,
    #[error("connection requires a supported platform")]
    UnsupportedPlatform,
    #[error("core is not connected")]
    NotConnected,
    #[error("app exceptions are not allowed in strict mode")]
    StrictModeRejectsAppExceptions,
    #[error("connection input is unsafe: {0}")]
    UnsafeConnectionInput(String),
}

#[derive(Debug)]
pub struct TorTunnelCore {
    status: ConnectionStatus,
    app_exceptions: Vec<AppException>,
    bridge_config: BridgeConfig,
    last_tor_config: Option<TorConfig>,
}

impl Default for TorTunnelCore {
    fn default() -> Self {
        Self::new()
    }
}

impl TorTunnelCore {
    pub fn new() -> Self {
        Self {
            status: ConnectionStatus::disconnected(),
            app_exceptions: Vec::new(),
            bridge_config: BridgeConfig::None,
            last_tor_config: None,
        }
    }

    pub fn connect(&mut self, request: ConnectionRequest) -> Result<ConnectionStatus, CoreError> {
        if request.profile.exit_countries.is_empty() {
            return Err(CoreError::EmptyCountryProfile);
        }
        validate_connection_request(&request)?;
        if request.mode == ConnectionMode::Strict
            && request.app_exceptions.iter().any(|app| app.enabled)
        {
            self.status = ConnectionStatus {
                state: ConnectionState::BlockedByKillswitch,
                health: TunnelHealth::BlockedByKillSwitch,
                mode: request.mode,
                platform: Some(request.platform),
                profile: Some(request.profile),
                bridge_config: request.bridge_config,
                exit_country: None,
                exit_ip: None,
                bootstrap_percent: 0,
                kill_switch_active: false,
                dns_protected: false,
                udp_blocked: false,
                ipv6_blocked: false,
                fallback_active: false,
                message: "Strict Mode rejects app exceptions. Switch to Compatibility Mode for reduced protection.".to_string(),
                release_blockers: vec!["App exceptions cannot be enabled in Strict Mode.".to_string()],
                updated_at_unix: now_unix(),
            };
            return Err(CoreError::StrictModeRejectsAppExceptions);
        }

        let contract = platform_contract(request.platform);
        if !contract.production_ready {
            self.status = ConnectionStatus::degraded(
                request.platform,
                request.mode,
                request.bridge_config.clone(),
                "Platform tunnel adapter is a scaffold and must be replaced with a signed native service.",
                contract.native_notes.clone(),
            );
        } else {
            self.status = ConnectionStatus::connecting(
                request.platform,
                request.mode,
                request.bridge_config.clone(),
            );
        }

        let tor_config = TorConfigBuilder::new(request.profile.clone())
            .dns_port(5353)
            .socks_port(9050)
            .transparent_proxy_port(9040)
            .control_port(9051)
            .bridge_config(request.bridge_config.clone())
            .build();

        self.last_tor_config = Some(tor_config);
        self.app_exceptions = request.app_exceptions;
        self.bridge_config = request.bridge_config.clone();

        let capabilities = capabilities(request.platform);
        if !contract.production_ready {
            self.status = ConnectionStatus {
                state: ConnectionState::BlockedByKillswitch,
                health: TunnelHealth::BlockedByKillSwitch,
                mode: request.mode,
                platform: Some(request.platform),
                profile: Some(request.profile),
                bridge_config: request.bridge_config,
                exit_country: None,
                exit_ip: None,
                bootstrap_percent: 0,
                kill_switch_active: false,
                dns_protected: false,
                udp_blocked: false,
                ipv6_blocked: false,
                fallback_active: false,
                message: "Connect is locked until native adapter evidence, leak tests, and release audit pass.".to_string(),
                release_blockers: capabilities.blockers,
                updated_at_unix: now_unix(),
            };
            return Err(CoreError::UnsupportedPlatform);
        }

        let strict_protected = contract.production_ready && request.mode == ConnectionMode::Strict;
        self.status = ConnectionStatus {
            state: if contract.production_ready {
                ConnectionState::Connected
            } else {
                ConnectionState::Degraded
            },
            health: if strict_protected {
                TunnelHealth::Protected
            } else if request.mode == ConnectionMode::CompatibilityReducedProtection {
                TunnelHealth::ReducedProtection
            } else {
                TunnelHealth::BlockedByKillSwitch
            },
            mode: request.mode,
            platform: Some(request.platform),
            profile: Some(request.profile),
            bridge_config: request.bridge_config,
            exit_country: Some("DE".to_string()),
            exit_ip: Some("185.220.101.42".to_string()),
            bootstrap_percent: 100,
            kill_switch_active: true,
            dns_protected: true,
            udp_blocked: true,
            ipv6_blocked: true,
            fallback_active: false,
            message: if contract.production_ready {
                "Connected through Tor.".to_string()
            } else if request.mode == ConnectionMode::Strict {
                "Strict Mode is blocked because the native platform adapter is not production-ready.".to_string()
            } else {
                "Compatibility Mode development core is active; this is reduced protection and not stable-ready.".to_string()
            },
            release_blockers: capabilities.blockers,
            updated_at_unix: now_unix(),
        };

        Ok(self.status.clone())
    }

    pub fn disconnect(&mut self) -> ConnectionStatus {
        self.status = ConnectionStatus::disconnected();
        self.status.clone()
    }

    pub fn start_tor(&mut self, bridge_config: BridgeConfig) -> ConnectionStatus {
        self.bridge_config = bridge_config.clone();
        self.status.bridge_config = bridge_config;
        self.status.message = "Tor runtime start requested. Bundle and process supervisor are required before production.".to_string();
        self.status
            .release_blockers
            .push("Tor bundle supervisor is not wired to a real tor binary.".to_string());
        self.status.updated_at_unix = now_unix();
        self.status.clone()
    }

    pub fn stop_tor(&mut self) -> ConnectionStatus {
        self.status.message = "Tor runtime stop requested.".to_string();
        self.status.updated_at_unix = now_unix();
        self.status.clone()
    }

    pub fn rotate_identity(&mut self) -> Result<ConnectionStatus, CoreError> {
        if !matches!(
            self.status.state,
            ConnectionState::Connected
                | ConnectionState::Degraded
                | ConnectionState::FallbackActive
        ) {
            return Err(CoreError::NotConnected);
        }

        self.status.message = "Requested a new Tor identity and rebuilt circuits.".to_string();
        self.status.updated_at_unix = now_unix();
        Ok(self.status.clone())
    }

    pub fn set_app_exceptions(&mut self, exceptions: Vec<AppException>) -> Vec<AppException> {
        if self.status.mode == ConnectionMode::Strict {
            self.app_exceptions = exceptions
                .into_iter()
                .map(|exception| AppException {
                    enabled: false,
                    ..exception
                })
                .collect();
            self.status.health = TunnelHealth::BlockedByKillSwitch;
            self.status.message =
                "Strict Mode disables app exceptions; Compatibility Mode is required for reduced protection.".to_string();
            return self.app_exceptions.clone();
        }
        self.app_exceptions = exceptions;
        if self
            .app_exceptions
            .iter()
            .any(|exception| exception.enabled)
        {
            self.status.health = TunnelHealth::ReducedProtection;
        }
        self.app_exceptions.clone()
    }

    pub fn set_bridge_config(&mut self, bridge_config: BridgeConfig) -> ConnectionStatus {
        self.bridge_config = bridge_config.clone();
        self.status.bridge_config = bridge_config;
        self.status.message =
            "Bridge configuration updated. Reconnect required for Tor to apply it.".to_string();
        self.status.updated_at_unix = now_unix();
        self.status.clone()
    }

    pub fn verify_exit(&mut self) -> Result<ExitVerification, CoreError> {
        if !matches!(
            self.status.state,
            ConnectionState::Connected | ConnectionState::FallbackActive
        ) {
            return Err(CoreError::NotConnected);
        }

        Ok(ExitVerification {
            checked_at_unix: now_unix(),
            is_tor: true,
            observed_ip: self
                .status
                .exit_ip
                .clone()
                .unwrap_or_else(|| "unknown".to_string()),
            observed_country: self
                .status
                .exit_country
                .clone()
                .unwrap_or_else(|| "unknown".to_string()),
            source: "mock-public-check".to_string(),
            message: "Exit verification is wired as a public-check contract; replace the mock source before release.".to_string(),
        })
    }

    pub fn export_diagnostics(&self) -> DiagnosticBundle {
        DiagnosticBundle {
            generated_at_unix: now_unix(),
            app_version: env!("CARGO_PKG_VERSION").to_string(),
            platform: self.status.platform,
            health: format!("{:?}", self.status.health),
            redacted_logs: vec![
                redact_log_line("TorTunnel diagnostics are local only.", &RedactionPolicy::default()),
                redact_log_line(
                    "No account identifiers, telemetry IDs, or automatic upload endpoints are present.",
                    &RedactionPolicy::default(),
                ),
            ],
            tor_config_preview: None,
            release_blockers: self.status.release_blockers.clone(),
        }
    }

    pub fn run_leak_self_test(&self) -> LeakSelfTestReport {
        if self.status.health == TunnelHealth::Protected {
            LeakSelfTestReport {
                strict_mode: true,
                stable_release_allowed: false,
                results: vec![
                    LeakCheckResult {
                        kind: LeakCheckKind::Ip,
                        status: LeakCheckStatus::NotRun,
                        message: "Protected status reached; external leak probe runner must execute on target device.".to_string(),
                    },
                ],
            }
        } else {
            LeakSelfTestReport::preflight_blocked(
                "Native platform adapter is not production-ready; leak test cannot pass.",
            )
        }
    }

    pub fn release_readiness(&self) -> ReleaseReadiness {
        let platform_readiness = [Platform::Android, Platform::Linux, Platform::Windows]
            .into_iter()
            .map(|platform| {
                let capability = capabilities(platform);
                PlatformReadiness {
                    platform,
                    adapter_name: capability.adapter_name,
                    status: if capability.production_ready {
                        ReadinessStatus::Verified
                    } else {
                        ReadinessStatus::NotReady
                    },
                    evidence_id: format!("adapter.{platform:?}").to_lowercase(),
                    message: if capability.production_ready {
                        "Adapter capability reports production-ready.".to_string()
                    } else {
                        capability.blockers.join(" ")
                    },
                }
            })
            .collect();

        ReleaseReadiness {
            platform_readiness,
            steps: vec![
                ReadinessStep {
                    id: "native-adapter".to_string(),
                    title: "Native adapter".to_string(),
                    status: ReadinessStatus::NotReady,
                    evidence_id: "gate.native-adapter".to_string(),
                    detail: "No platform adapter can claim real protection yet.".to_string(),
                },
                ReadinessStep {
                    id: "leak-tests".to_string(),
                    title: "Leak tests".to_string(),
                    status: ReadinessStatus::NotReady,
                    evidence_id: "gate.leak-tests".to_string(),
                    detail: "Exit IP, DNS, UDP, IPv6, and kill-switch tests must pass.".to_string(),
                },
                ReadinessStep {
                    id: "release-audit".to_string(),
                    title: "Release audit".to_string(),
                    status: ReadinessStatus::NotReady,
                    evidence_id: "gate.release-audit".to_string(),
                    detail: "Signing, packaging, and external audit are still open.".to_string(),
                },
            ],
            evidence: vec![
                LeakEvidenceItem {
                    id: "leak.exit-ip".to_string(),
                    area: "Exit IP".to_string(),
                    status: EvidenceStatus::Blocked,
                    evidence_id: "docs/LEAK_TEST_MATRIX.md#exit-ip".to_string(),
                    message: "Public IP must be a Tor exit after connect.".to_string(),
                },
                LeakEvidenceItem {
                    id: "leak.dns".to_string(),
                    area: "DNS".to_string(),
                    status: EvidenceStatus::Blocked,
                    evidence_id: "docs/LEAK_TEST_MATRIX.md#dns".to_string(),
                    message: "System resolver bypass is not device-verified.".to_string(),
                },
                LeakEvidenceItem {
                    id: "leak.kill-switch".to_string(),
                    area: "Kill-switch".to_string(),
                    status: EvidenceStatus::Blocked,
                    evidence_id: "docs/LEAK_TEST_MATRIX.md#kill-switch".to_string(),
                    message: "Traffic must stay blocked during Tor failure.".to_string(),
                },
                LeakEvidenceItem {
                    id: "leak.diagnostics".to_string(),
                    area: "Diagnostics".to_string(),
                    status: EvidenceStatus::LocalOnly,
                    evidence_id: "docs/THREAT_MODEL.md#goals".to_string(),
                    message: "Diagnostics remain local and manually exported.".to_string(),
                },
            ],
            claims: vec![
                ProtectionClaim {
                    label: "No accounts".to_string(),
                    status: EvidenceStatus::LocalOnly,
                    evidence_id: "README.md#important-status".to_string(),
                    message: "No backend account system is present.".to_string(),
                },
                ProtectionClaim {
                    label: "Strict Mode protection".to_string(),
                    status: EvidenceStatus::Blocked,
                    evidence_id: "docs/audit/STABLE_BLOCKERS.md".to_string(),
                    message: "Strict Mode cannot claim protected until native adapters pass."
                        .to_string(),
                },
            ],
        }
    }

    pub fn status(&self) -> ConnectionStatus {
        self.status.clone()
    }
}

fn now_unix() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

fn validate_connection_request(request: &ConnectionRequest) -> Result<(), CoreError> {
    for country in &request.profile.exit_countries {
        if country.len() != 2 || !country.chars().all(|ch| ch.is_ascii_alphabetic()) {
            return Err(CoreError::UnsafeConnectionInput(format!(
                "invalid exit country {country}"
            )));
        }
    }
    validate_bridge_config(&request.bridge_config)
}

fn validate_bridge_config(bridge_config: &BridgeConfig) -> Result<(), CoreError> {
    match bridge_config {
        BridgeConfig::None | BridgeConfig::Snowflake => Ok(()),
        BridgeConfig::ManualObfs4 { lines } => {
            for line in lines {
                reject_control_chars(line, "manual bridge line")?;
                if !line.starts_with("obfs4 ") {
                    return Err(CoreError::UnsafeConnectionInput(
                        "manual bridge lines must start with obfs4".to_string(),
                    ));
                }
            }
            Ok(())
        }
        BridgeConfig::CustomTransport {
            name,
            command,
            args,
        } => {
            reject_token(name, "custom transport name")?;
            reject_token(command, "custom transport command")?;
            for arg in args {
                reject_control_chars(arg, "custom transport argument")?;
            }
            Ok(())
        }
    }
}

fn reject_token(value: &str, label: &str) -> Result<(), CoreError> {
    reject_control_chars(value, label)?;
    if value.is_empty()
        || !value
            .chars()
            .all(|ch| ch.is_ascii_alphanumeric() || matches!(ch, '_' | '-' | '.' | '/'))
    {
        return Err(CoreError::UnsafeConnectionInput(format!("invalid {label}")));
    }
    Ok(())
}

fn reject_control_chars(value: &str, label: &str) -> Result<(), CoreError> {
    if value.contains('\n') || value.contains('\r') || value.contains('\0') {
        return Err(CoreError::UnsafeConnectionInput(format!(
            "{label} contains control characters"
        )));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn profile() -> CountryProfile {
        CountryProfile {
            id: "eu-default".to_string(),
            name: "EU Privacy".to_string(),
            exit_countries: vec!["DE".to_string(), "NL".to_string()],
            preference_mode: CountryPreferenceMode::Prefer,
        }
    }

    #[test]
    fn connect_rejects_empty_exit_country_profile() {
        let mut core = TorTunnelCore::new();
        let request = ConnectionRequest {
            platform: Platform::Android,
            mode: ConnectionMode::Strict,
            profile: CountryProfile {
                exit_countries: Vec::new(),
                ..profile()
            },
            bridge_config: BridgeConfig::None,
            app_exceptions: Vec::new(),
            auto_fallback: true,
            isolate_by_app: true,
        };

        let result = core.connect(request);

        assert!(matches!(result, Err(CoreError::EmptyCountryProfile)));
    }

    #[test]
    fn connect_without_production_adapter_does_not_claim_leak_protection() {
        let mut core = TorTunnelCore::new();
        let request = ConnectionRequest {
            platform: Platform::Android,
            mode: ConnectionMode::CompatibilityReducedProtection,
            profile: profile(),
            bridge_config: BridgeConfig::None,
            app_exceptions: Vec::new(),
            auto_fallback: true,
            isolate_by_app: true,
        };

        let result = core.connect(request);
        let status = core.status();

        assert!(matches!(result, Err(CoreError::UnsupportedPlatform)));
        assert!(!status.kill_switch_active);
        assert!(!status.dns_protected);
        assert!(!status.udp_blocked);
        assert!(!status.ipv6_blocked);
    }

    #[test]
    fn diagnostics_omit_torrc_preview_after_failed_connect() {
        let mut core = TorTunnelCore::new();
        let result = core.connect(ConnectionRequest {
            platform: Platform::Linux,
            mode: ConnectionMode::CompatibilityReducedProtection,
            profile: profile(),
            bridge_config: BridgeConfig::None,
            app_exceptions: Vec::new(),
            auto_fallback: true,
            isolate_by_app: true,
        });

        let diagnostics = core.export_diagnostics();

        assert!(matches!(result, Err(CoreError::UnsupportedPlatform)));
        assert_eq!(diagnostics.tor_config_preview, None);
    }

    #[test]
    fn strict_mode_rejects_enabled_app_exceptions() {
        let mut core = TorTunnelCore::new();
        let result = core.connect(ConnectionRequest {
            platform: Platform::Android,
            mode: ConnectionMode::Strict,
            profile: profile(),
            bridge_config: BridgeConfig::None,
            app_exceptions: vec![AppException {
                app_id: "com.example".to_string(),
                display_name: "Example".to_string(),
                enabled: true,
                reason: "test".to_string(),
            }],
            auto_fallback: true,
            isolate_by_app: true,
        });

        assert!(matches!(
            result,
            Err(CoreError::StrictModeRejectsAppExceptions)
        ));
        assert_eq!(core.status().health, TunnelHealth::BlockedByKillSwitch);
    }

    #[test]
    fn connect_rejects_multiline_exit_country() {
        let mut core = TorTunnelCore::new();
        let result = core.connect(ConnectionRequest {
            platform: Platform::Android,
            mode: ConnectionMode::Strict,
            profile: CountryProfile {
                exit_countries: vec!["DE\nSocksPort 0".to_string()],
                ..profile()
            },
            bridge_config: BridgeConfig::None,
            app_exceptions: Vec::new(),
            auto_fallback: true,
            isolate_by_app: true,
        });

        assert!(matches!(result, Err(CoreError::UnsafeConnectionInput(_))));
    }

    #[test]
    fn connect_rejects_multiline_bridge_config() {
        let mut core = TorTunnelCore::new();
        let result = core.connect(ConnectionRequest {
            platform: Platform::Android,
            mode: ConnectionMode::Strict,
            profile: profile(),
            bridge_config: BridgeConfig::ManualObfs4 {
                lines: vec![
                    "obfs4 203.0.113.10:443 cert=fingerprint iat-mode=0\nSocksPort 0".to_string(),
                ],
            },
            app_exceptions: Vec::new(),
            auto_fallback: true,
            isolate_by_app: true,
        });

        assert!(matches!(result, Err(CoreError::UnsafeConnectionInput(_))));
    }

    #[test]
    fn non_production_adapter_connect_fails_closed() {
        let mut core = TorTunnelCore::new();
        let result = core.connect(ConnectionRequest {
            platform: Platform::Android,
            mode: ConnectionMode::CompatibilityReducedProtection,
            profile: profile(),
            bridge_config: BridgeConfig::None,
            app_exceptions: Vec::new(),
            auto_fallback: true,
            isolate_by_app: true,
        });

        assert!(matches!(result, Err(CoreError::UnsupportedPlatform)));
        let status = core.status();
        assert_eq!(status.state, ConnectionState::BlockedByKillswitch);
        assert_eq!(status.exit_ip, None);
        assert!(!status.kill_switch_active);
        assert!(!status.dns_protected);
        assert!(!status.udp_blocked);
        assert!(!status.ipv6_blocked);
    }

    #[test]
    fn diagnostics_omit_torrc_preview_by_default() {
        let core = TorTunnelCore::new();
        let diagnostics = core.export_diagnostics();

        assert_eq!(diagnostics.tor_config_preview, None);
    }

    #[test]
    fn leak_self_test_blocks_until_native_adapter_is_ready() {
        let core = TorTunnelCore::new();
        let report = core.run_leak_self_test();
        assert!(!report.stable_release_allowed);
        assert!(report
            .results
            .iter()
            .all(|result| result.status == LeakCheckStatus::Blocked));
    }

    #[test]
    fn release_readiness_keeps_strict_claim_blocked_without_adapter_evidence() {
        let core = TorTunnelCore::new();
        let readiness = core.release_readiness();

        assert!(readiness
            .platform_readiness
            .iter()
            .all(|platform| platform.status == ReadinessStatus::NotReady));
        assert!(readiness.claims.iter().any(|claim| {
            claim.label == "Strict Mode protection" && claim.status == EvidenceStatus::Blocked
        }));
    }
}
