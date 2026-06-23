//! Pure description of the Linux system-wide tunnel setup.
//!
//! Everything that decides *what* commands and rules to apply lives here so it
//! is unit-testable without root or a real network. The runtime in `main.rs`
//! only executes what this module produces.

use tor_tunnel_tunnel_engine::KillSwitchPlan;

/// A fully-resolved plan for the Linux system tunnel.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TunnelPlan {
    pub tun_name: String,
    pub tun_addr: String,
    pub tun_prefix: u8,
    pub socks_port: u16,
    pub tor_uid: u32,
    pub exit_country: String,
}

impl TunnelPlan {
    /// Strict defaults: TUN `tortun0`, leak-protection on.
    pub fn strict_default(exit_country: impl Into<String>, tor_uid: u32) -> Self {
        Self {
            tun_name: "tortun0".to_string(),
            tun_addr: "10.111.0.2".to_string(),
            tun_prefix: 24,
            socks_port: 9050,
            tor_uid,
            exit_country: exit_country.into(),
        }
    }

    /// The nftables kill-switch ruleset for this plan.
    pub fn nftables(&self) -> String {
        KillSwitchPlan::strict(&self.tun_name, self.tor_uid).render()
    }

    /// `ip` invocations that create, address, and route the TUN device.
    pub fn tun_setup_commands(&self) -> Vec<Vec<String>> {
        vec![
            owned(&["ip", "tuntap", "add", "dev", &self.tun_name, "mode", "tun"]),
            owned(&[
                "ip",
                "addr",
                "add",
                &format!("{}/{}", self.tun_addr, self.tun_prefix),
                "dev",
                &self.tun_name,
            ]),
            owned(&["ip", "link", "set", "dev", &self.tun_name, "up"]),
            owned(&[
                "ip",
                "route",
                "add",
                "default",
                "dev",
                &self.tun_name,
                "metric",
                "1",
            ]),
        ]
    }

    /// `ip` invocations that remove the TUN device and its route.
    pub fn tun_teardown_commands(&self) -> Vec<Vec<String>> {
        vec![
            owned(&["ip", "route", "del", "default", "dev", &self.tun_name]),
            owned(&["ip", "link", "del", "dev", &self.tun_name]),
        ]
    }

    /// Arguments for the `tun2proxy` process that bridges the TUN to tor's SOCKS.
    pub fn tun2proxy_args(&self) -> Vec<String> {
        owned(&[
            "--tun",
            &self.tun_name,
            "--proxy",
            &format!("socks5://127.0.0.1:{}", self.socks_port),
            "--dns",
            "virtual",
        ])
    }
}

fn owned(parts: &[&str]) -> Vec<String> {
    parts.iter().map(|part| (*part).to_string()).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn nftables_is_a_default_drop_kill_switch() {
        let plan = TunnelPlan::strict_default("DE", 108);
        let nft = plan.nftables();
        assert!(nft.contains("policy drop"));
        assert!(nft.contains("oifname \"tortun0\" accept"));
        assert!(nft.contains("meta skuid 108 accept"));
    }

    #[test]
    fn tun_setup_creates_and_routes_device() {
        let plan = TunnelPlan::strict_default("DE", 108);
        let commands = plan.tun_setup_commands();
        assert_eq!(
            commands[0],
            owned(&["ip", "tuntap", "add", "dev", "tortun0", "mode", "tun"])
        );
        assert!(commands
            .iter()
            .any(|c| c.contains(&"default".to_string()) && c.contains(&"tortun0".to_string())));
    }

    #[test]
    fn teardown_reverses_setup() {
        let plan = TunnelPlan::strict_default("DE", 108);
        let teardown = plan.tun_teardown_commands();
        assert!(teardown.iter().any(|c| c.contains(&"del".to_string())));
    }

    #[test]
    fn tun2proxy_points_at_tor_socks() {
        let plan = TunnelPlan::strict_default("DE", 108);
        let args = plan.tun2proxy_args();
        assert!(args.contains(&"socks5://127.0.0.1:9050".to_string()));
        assert!(args.contains(&"tortun0".to_string()));
    }
}
