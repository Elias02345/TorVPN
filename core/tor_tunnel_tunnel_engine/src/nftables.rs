//! nftables ruleset generation for the Linux kill-switch / transparent Tor proxy.
//!
//! [`KillSwitchPlan::render`] produces a `nft -f` script for the `inet tortunnel`
//! table that, by default, **drops** all output and only lets through:
//!  * already-established connections and loopback,
//!  * tor's own traffic (matched by uid), so tor can reach the network,
//!  * TCP redirected to tor's TransPort and DNS redirected to tor's DNSPort.
//!
//! UDP and IPv6 are dropped in the MVP. This module is pure and unit-testable;
//! the privileged helper applies the rendered ruleset. As with every TorTunnel
//! adapter it is **fail-closed**: the generated rules must pass the device
//! leak-test matrix before the tunnel may report `protected`.

use serde::{Deserialize, Serialize};

/// The nft command that removes the TorTunnel table (kill-switch teardown).
pub const TEARDOWN_COMMAND: &str = "delete table inet tortunnel";

/// Inputs that fully determine the generated kill-switch ruleset.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct KillSwitchPlan {
    /// The uid the tor process runs as; its traffic is allowed out directly.
    pub tor_uid: u32,
    /// Tor's TransPort, where redirected TCP is sent.
    pub trans_port: u16,
    /// Tor's DNSPort, where redirected DNS is sent.
    pub dns_port: u16,
    /// Drop UDP (DNS is redirected separately).
    pub block_udp: bool,
    /// Drop IPv6 entirely.
    pub block_ipv6: bool,
}

impl KillSwitchPlan {
    /// The strict-mode plan: block UDP and IPv6.
    pub fn strict(tor_uid: u32, trans_port: u16, dns_port: u16) -> Self {
        Self {
            tor_uid,
            trans_port,
            dns_port,
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
            "    chain output_nat {".to_string(),
            "        type nat hook output priority -100; policy accept;".to_string(),
            format!("        meta skuid {uid} return"),
            "        ip daddr 127.0.0.0/8 return".to_string(),
            format!(
                "        meta l4proto {{ tcp, udp }} th dport 53 redirect to :{}",
                self.dns_port
            ),
            format!("        meta l4proto tcp redirect to :{}", self.trans_port),
            "    }".to_string(),
            "    chain output_filter {".to_string(),
            "        type filter hook output priority 0; policy drop;".to_string(),
            "        ct state established,related accept".to_string(),
            "        oifname \"lo\" accept".to_string(),
            format!("        meta skuid {uid} accept"),
            "        ip daddr 127.0.0.0/8 accept".to_string(),
        ];
        if self.block_ipv6 {
            lines.push("        meta nfproto ipv6 drop".to_string());
        }
        if self.block_udp {
            lines.push("        meta l4proto udp drop".to_string());
        }
        lines.push("        meta l4proto tcp accept".to_string());
        lines.push("    }".to_string());
        lines.push("}".to_string());
        lines.join("\n")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn render() -> String {
        KillSwitchPlan::strict(108, 9040, 5353).render()
    }

    #[test]
    fn declares_the_tortunnel_table_with_default_drop() {
        let nft = render();
        assert!(nft.contains("table inet tortunnel"));
        assert!(nft.contains("type filter hook output priority 0; policy drop;"));
    }

    #[test]
    fn allows_tor_uid_and_loopback() {
        let nft = render();
        assert!(nft.contains("meta skuid 108 accept"));
        assert!(nft.contains("oifname \"lo\" accept"));
    }

    #[test]
    fn redirects_tcp_and_dns_to_tor() {
        let nft = render();
        assert!(nft.contains("redirect to :9040"));
        assert!(nft.contains("th dport 53 redirect to :5353"));
    }

    #[test]
    fn strict_blocks_udp_and_ipv6() {
        let nft = render();
        assert!(nft.contains("meta nfproto ipv6 drop"));
        assert!(nft.contains("meta l4proto udp drop"));
    }

    #[test]
    fn relaxed_plan_omits_blocks() {
        let plan = KillSwitchPlan {
            tor_uid: 108,
            trans_port: 9040,
            dns_port: 5353,
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
