use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum PacketDecision {
    RouteToTor,
    InterceptDns,
    BlockUdp,
    BlockIpv6,
    RejectDirectFallback,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TunnelPolicy {
    pub strict_mode: bool,
    pub route_tcp_to_socks: bool,
    pub intercept_dns: bool,
    pub block_udp: bool,
    pub block_ipv6: bool,
    pub allow_direct_fallback: bool,
    pub engine: String,
    pub vendored_revision: Option<String>,
}

impl TunnelPolicy {
    pub fn strict() -> Self {
        Self {
            strict_mode: true,
            route_tcp_to_socks: true,
            intercept_dns: true,
            block_udp: true,
            block_ipv6: true,
            allow_direct_fallback: false,
            engine: "vendored-tun2proxy".to_string(),
            vendored_revision: None,
        }
    }
}

pub fn classify_packet(protocol: &str, is_ipv6: bool, is_dns: bool) -> PacketDecision {
    if is_ipv6 {
        return PacketDecision::BlockIpv6;
    }
    if is_dns {
        return PacketDecision::InterceptDns;
    }
    if protocol.eq_ignore_ascii_case("udp") {
        return PacketDecision::BlockUdp;
    }
    if protocol.eq_ignore_ascii_case("tcp") {
        return PacketDecision::RouteToTor;
    }
    PacketDecision::RejectDirectFallback
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn strict_policy_never_allows_direct_fallback() {
        let policy = TunnelPolicy::strict();
        assert!(!policy.allow_direct_fallback);
        assert!(policy.block_udp);
        assert!(policy.block_ipv6);
    }
}
