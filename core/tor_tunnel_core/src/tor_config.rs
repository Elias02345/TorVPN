use crate::{BridgeConfig, CountryProfile};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TorConfig {
    pub profile: CountryProfile,
    pub socks_port: u16,
    pub dns_port: u16,
    pub transparent_proxy_port: u16,
    pub control_port: u16,
    pub isolate_by_app: bool,
    pub bridge_config: BridgeConfig,
}

impl TorConfig {
    pub fn to_torrc(&self) -> String {
        let exit_nodes = self
            .profile
            .exit_countries
            .iter()
            .map(|country| format!("{{{}}}", country.to_uppercase()))
            .collect::<Vec<_>>()
            .join(",");

        let isolation_flags = if self.isolate_by_app {
            " IsolateSOCKSAuth IsolateClientProtocol"
        } else {
            ""
        };

        let mut lines = vec![
            "ClientOnly 1".to_string(),
            "AvoidDiskWrites 1".to_string(),
            "CookieAuthentication 1".to_string(),
            "AutomapHostsOnResolve 1".to_string(),
            "VirtualAddrNetworkIPv4 10.192.0.0/10".to_string(),
            format!("SocksPort 127.0.0.1:{}{}", self.socks_port, isolation_flags),
            format!("DNSPort 127.0.0.1:{}", self.dns_port),
            format!("TransPort 127.0.0.1:{}", self.transparent_proxy_port),
            format!("ControlPort 127.0.0.1:{}", self.control_port),
            format!("ExitNodes {}", exit_nodes),
            "StrictNodes 0".to_string(),
            "# TorTunnel blocks UDP and IPv6 at the platform tunnel layer in MVP.".to_string(),
        ];
        lines.extend(self.bridge_lines());
        lines.join("\n")
    }

    fn bridge_lines(&self) -> Vec<String> {
        match &self.bridge_config {
            BridgeConfig::None => Vec::new(),
            BridgeConfig::ManualObfs4 { lines } => {
                let mut config = vec![
                    "UseBridges 1".to_string(),
                    "ClientTransportPlugin obfs4 exec obfs4proxy".to_string(),
                ];
                config.extend(lines.iter().map(|line| format!("Bridge {}", line)));
                config
            }
            BridgeConfig::Snowflake => vec![
                "UseBridges 1".to_string(),
                "ClientTransportPlugin snowflake exec snowflake-client".to_string(),
                "Bridge snowflake 192.0.2.3:1".to_string(),
            ],
            BridgeConfig::CustomTransport {
                name,
                command,
                args,
            } => vec![
                "UseBridges 1".to_string(),
                format!(
                    "ClientTransportPlugin {} exec {} {}",
                    name,
                    command,
                    args.join(" ")
                ),
            ],
        }
    }
}

#[derive(Debug, Clone)]
pub struct TorConfigBuilder {
    profile: CountryProfile,
    socks_port: u16,
    dns_port: u16,
    transparent_proxy_port: u16,
    control_port: u16,
    isolate_by_app: bool,
    bridge_config: BridgeConfig,
}

impl TorConfigBuilder {
    pub fn new(profile: CountryProfile) -> Self {
        Self {
            profile,
            socks_port: 9050,
            dns_port: 5353,
            transparent_proxy_port: 9040,
            control_port: 9051,
            isolate_by_app: true,
            bridge_config: BridgeConfig::None,
        }
    }

    pub fn socks_port(mut self, port: u16) -> Self {
        self.socks_port = port;
        self
    }

    pub fn dns_port(mut self, port: u16) -> Self {
        self.dns_port = port;
        self
    }

    pub fn transparent_proxy_port(mut self, port: u16) -> Self {
        self.transparent_proxy_port = port;
        self
    }

    pub fn control_port(mut self, port: u16) -> Self {
        self.control_port = port;
        self
    }

    pub fn isolate_by_app(mut self, isolate: bool) -> Self {
        self.isolate_by_app = isolate;
        self
    }

    pub fn bridge_config(mut self, bridge_config: BridgeConfig) -> Self {
        self.bridge_config = bridge_config;
        self
    }

    pub fn build(self) -> TorConfig {
        TorConfig {
            profile: self.profile,
            socks_port: self.socks_port,
            dns_port: self.dns_port,
            transparent_proxy_port: self.transparent_proxy_port,
            control_port: self.control_port,
            isolate_by_app: self.isolate_by_app,
            bridge_config: self.bridge_config,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{BridgeConfig, CountryPreferenceMode};

    #[test]
    fn torrc_prefers_exit_countries_without_strict_nodes() {
        let config = TorConfigBuilder::new(CountryProfile {
            id: "privacy".to_string(),
            name: "Privacy".to_string(),
            exit_countries: vec!["de".to_string(), "nl".to_string()],
            preference_mode: CountryPreferenceMode::Prefer,
        })
        .build();

        let torrc = config.to_torrc();

        assert!(torrc.contains("ExitNodes {DE},{NL}"));
        assert!(torrc.contains("StrictNodes 0"));
        assert!(torrc.contains("AutomapHostsOnResolve 1"));
    }

    #[test]
    fn torrc_includes_manual_obfs4_bridges() {
        let config = TorConfigBuilder::new(CountryProfile {
            id: "bridge".to_string(),
            name: "Bridge".to_string(),
            exit_countries: vec!["DE".to_string()],
            preference_mode: CountryPreferenceMode::Prefer,
        })
        .bridge_config(BridgeConfig::ManualObfs4 {
            lines: vec!["obfs4 203.0.113.10:443 cert=fingerprint iat-mode=0".to_string()],
        })
        .build();

        let torrc = config.to_torrc();

        assert!(torrc.contains("UseBridges 1"));
        assert!(torrc.contains("ClientTransportPlugin obfs4 exec obfs4proxy"));
        assert!(torrc.contains("Bridge obfs4 203.0.113.10:443"));
    }
}
