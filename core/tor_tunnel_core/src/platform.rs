use crate::Platform;
use tor_tunnel_platform_contracts::capabilities;

#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub struct PlatformTunnelContract {
    pub platform: Platform,
    pub adapter_name: String,
    pub tcp_over_tor_required: bool,
    pub dns_over_tor_required: bool,
    pub kill_switch_required: bool,
    pub udp_block_required: bool,
    pub ipv6_block_required: bool,
    pub app_exceptions_supported: bool,
    pub production_ready: bool,
    pub native_notes: Vec<String>,
}

pub fn platform_contract(platform: Platform) -> PlatformTunnelContract {
    let platform_capabilities = capabilities(platform);
    match platform {
        Platform::Android => PlatformTunnelContract {
            platform,
            adapter_name: "Android VpnService".to_string(),
            tcp_over_tor_required: true,
            dns_over_tor_required: true,
            kill_switch_required: true,
            udp_block_required: true,
            ipv6_block_required: true,
            app_exceptions_supported: true,
            production_ready: platform_capabilities.production_ready,
            native_notes: platform_capabilities.blockers,
        },
        Platform::Linux => PlatformTunnelContract {
            platform,
            adapter_name: "Privileged TUN service with nftables".to_string(),
            tcp_over_tor_required: true,
            dns_over_tor_required: true,
            kill_switch_required: true,
            udp_block_required: true,
            ipv6_block_required: true,
            app_exceptions_supported: false,
            production_ready: platform_capabilities.production_ready,
            native_notes: platform_capabilities.blockers,
        },
        Platform::Windows => PlatformTunnelContract {
            platform,
            adapter_name: "Windows service with Wintun and WFP".to_string(),
            tcp_over_tor_required: true,
            dns_over_tor_required: true,
            kill_switch_required: true,
            udp_block_required: true,
            ipv6_block_required: true,
            app_exceptions_supported: false,
            production_ready: platform_capabilities.production_ready,
            native_notes: platform_capabilities.blockers,
        },
    }
}
