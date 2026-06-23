//! nftables kill-switch generation for the Linux system tunnel.
//!
//! TorTunnel routes traffic with a TUN device + `tun2proxy` into tor's SOCKS
//! port. The nftables ruleset is the **kill-switch**: it default-drops all
//! output and only allows loopback, traffic into the tunnel device, and tor's
//! own connections (matched by uid). If `tun2proxy` or tor dies, traffic is
//! dropped rather than leaking directly.
//!
//! [`KillSwitchPlan::render`] is pure and unit-testable; the privileged helper
//! applies it. As with every TorTunnel adapter it is **fail-closed**: the
//! generated rules must pass the device leak-test matrix before the tunnel may
//! report `protected`.

use serde::{Deserialize, Serialize};

/// The nft command that removes the TorTunnel table (kill-switch teardown).
pub const TEARDOWN_COMMAND: &str = "delete table inet tortunnel";

/// Inputs that fully determine the generated kill-switch ruleset.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct KillSwitchPlan {
    /// The TUN device that carries tunneled traffic (allowed out).
    pub tun_name: String,
    /// The uid the tor process runs as; its connections to relays are allowed.
    pub tor_uid: u32,
    /// Drop UDP that is not carried by the tunnel.
    pub block_udp: bool,
    /// Drop IPv6 that is not carried by the tunnel.
    pub block_ipv6: bool,
}

impl KillSwitchPlan {
    /// The strict-mode kill-switch: block direct UDP and IPv6.
    pub fn strict(tun_name: impl Into<String>, tor_uid: u32) -> Self {
        Self {
            tun_name: tun_name.into(),
            tor_uid,
            block_udp: true,
            block_ipv6: true,
        }
    }

    /// Render the `nft -f` ruleset for the `inet tortunnel` table.
    pub fn render(&self) -> String {
        let uid = self.tor_uid;
        let mut lines = vec![
            "# TorTunnel Linux kill-switch (fail-closed).".to_string(),
            "# Generated; must pass the device leak-test matrix before it is trusted.".to_string(),
            "table inet tortunnel {".to_string(),
            "    chain output {".to_string(),
            "        type filter hook output priority 0; policy drop;".to_string(),
            "        ct state established,related accept".to_string(),
            "        oifname \"lo\" accept".to_string(),
            format!("        oifname \"{}\" accept", self.tun_name),
            format!("        meta skuid {uid} accept"),
        ];
        if self.block_ipv6 {
            lines.push("        meta nfproto ipv6 drop".to_string());
        }
        if self.block_udp {
            lines.push("        meta l4proto udp drop".to_string());
        }
        lines.push("    }".to_string());
        lines.push("}".to_string());
        lines.join("\n")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn render() -> String {
        KillSwitchPlan::strict("tortun0", 108).render()
    }

    #[test]
    fn declares_the_tortunnel_table_with_default_drop() {
        let nft = render();
        assert!(nft.contains("table inet tortunnel"));
        assert!(nft.contains("type filter hook output priority 0; policy drop;"));
    }

    #[test]
    fn allows_loopback_tunnel_and_tor_uid() {
        let nft = render();
        assert!(nft.contains("oifname \"lo\" accept"));
        assert!(nft.contains("oifname \"tortun0\" accept"));
        assert!(nft.contains("meta skuid 108 accept"));
    }

    #[test]
    fn strict_blocks_direct_udp_and_ipv6() {
        let nft = render();
        assert!(nft.contains("meta nfproto ipv6 drop"));
        assert!(nft.contains("meta l4proto udp drop"));
    }

    #[test]
    fn relaxed_plan_omits_blocks() {
        let plan = KillSwitchPlan {
            tun_name: "tortun0".to_string(),
            tor_uid: 108,
            block_udp: false,
            block_ipv6: false,
        };
        let nft = plan.render();
        assert!(!nft.contains("meta nfproto ipv6 drop"));
        assert!(!nft.contains("meta l4proto udp drop"));
    }

    #[test]
    fn teardown_removes_the_table() {
        assert_eq!(TEARDOWN_COMMAND, "delete table inet tortunnel");
    }
}
