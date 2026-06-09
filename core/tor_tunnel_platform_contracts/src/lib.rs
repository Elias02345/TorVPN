use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Platform {
    Android,
    Linux,
    Windows,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PlatformCapabilities {
    pub platform: Platform,
    pub adapter_name: String,
    pub strict_mode_supported: bool,
    pub app_exceptions_supported: bool,
    pub app_exceptions_allowed_in_strict: bool,
    pub always_on_supported: bool,
    pub lockdown_detectable: bool,
    pub bridge_supported: bool,
    pub ipv6_supported: bool,
    pub udp_supported: bool,
    pub helper_version: Option<String>,
    pub signed_component_status: SignedComponentStatus,
    pub production_ready: bool,
    pub blockers: Vec<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum SignedComponentStatus {
    Missing,
    DevelopmentOnly,
    Signed,
    Verified,
}

pub fn capabilities(platform: Platform) -> PlatformCapabilities {
    match platform {
        Platform::Android => PlatformCapabilities {
            platform,
            adapter_name: "Android VpnService".to_string(),
            strict_mode_supported: false,
            app_exceptions_supported: true,
            app_exceptions_allowed_in_strict: false,
            always_on_supported: true,
            lockdown_detectable: true,
            bridge_supported: true,
            ipv6_supported: false,
            udp_supported: false,
            helper_version: None,
            signed_component_status: SignedComponentStatus::DevelopmentOnly,
            production_ready: false,
            blockers: vec![
                "VpnService packet loop must route TCP/DNS through Tor and block UDP/IPv6.".to_string(),
                "Lockdown behavior must be verified on real Android devices.".to_string(),
            ],
        },
        Platform::Linux => PlatformCapabilities {
            platform,
            adapter_name: "systemd/polkit helper with TUN and nftables".to_string(),
            strict_mode_supported: false,
            app_exceptions_supported: false,
            app_exceptions_allowed_in_strict: false,
            always_on_supported: true,
            lockdown_detectable: false,
            bridge_supported: true,
            ipv6_supported: false,
            udp_supported: false,
            helper_version: None,
            signed_component_status: SignedComponentStatus::Missing,
            production_ready: false,
            blockers: vec![
                "Privileged helper must create TUN and apply nftables default-deny before Tor bootstrap.".to_string(),
                "DEB/RPM/AppImage/Flatpak host-helper install paths must be signed and tested.".to_string(),
            ],
        },
        Platform::Windows => PlatformCapabilities {
            platform,
            adapter_name: "signed Windows service with Wintun and WFP".to_string(),
            strict_mode_supported: false,
            app_exceptions_supported: false,
            app_exceptions_allowed_in_strict: false,
            always_on_supported: true,
            lockdown_detectable: false,
            bridge_supported: true,
            ipv6_supported: false,
            udp_supported: false,
            helper_version: None,
            signed_component_status: SignedComponentStatus::Missing,
            production_ready: false,
            blockers: vec![
                "Wintun legal and signing review must pass.".to_string(),
                "WFP filters must block direct outbound traffic except the Tor service.".to_string(),
            ],
        },
    }
}
