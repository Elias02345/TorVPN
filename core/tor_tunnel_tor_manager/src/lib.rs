use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "kind", rename_all = "kebab-case")]
pub enum BridgeConfig {
    #[default]
    None,
    ManualObfs4 {
        lines: Vec<String>,
    },
    Snowflake,
    CustomTransport {
        name: String,
        command: String,
        args: Vec<String>,
    },
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TorRuntimeConfig {
    pub data_directory: String,
    pub socks_port: u16,
    pub dns_port: u16,
    pub transparent_proxy_port: u16,
    pub control_port: u16,
    pub cookie_authentication: bool,
    pub take_ownership: bool,
    pub bridge_config: BridgeConfig,
}

impl TorRuntimeConfig {
    pub fn development_default(data_directory: impl Into<String>) -> Self {
        Self {
            data_directory: data_directory.into(),
            socks_port: 9050,
            dns_port: 5353,
            transparent_proxy_port: 9040,
            control_port: 9051,
            cookie_authentication: true,
            take_ownership: true,
            bridge_config: BridgeConfig::None,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TorControlCommand {
    pub command: String,
}

pub fn newnym_command() -> TorControlCommand {
    TorControlCommand {
        command: "SIGNAL NEWNYM".to_string(),
    }
}

pub fn take_ownership_command() -> TorControlCommand {
    TorControlCommand {
        command: "TAKEOWNERSHIP".to_string(),
    }
}
