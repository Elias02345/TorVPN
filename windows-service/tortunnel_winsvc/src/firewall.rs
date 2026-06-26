//! Windows Filtering Platform kill-switch via the built-in firewall.
//!
//! The Windows tunnel mirrors Linux: a Wintun adapter (created by `tun2proxy`)
//! carries traffic to tor's SOCKS port, and a WFP-backed kill-switch blocks all
//! direct outbound traffic except tor itself. We drive WFP through the
//! `netsh advfirewall` interface (which sits on top of WFP) rather than raw FWPM
//! so the policy is inspectable and the command builders are pure and testable.
//!
//! Fail-closed: the default outbound action is set to **block**, so if tor or
//! `tun2proxy` dies, traffic does not leak. Must pass the device leak-test matrix
//! (see `docs/VERIFICATION_CHECKLIST.md`) before it is trusted.

/// The WFP kill-switch policy: block all outbound except tor's executable.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WindowsKillSwitch {
    pub tor_exe: String,
    pub rule_prefix: String,
}

impl WindowsKillSwitch {
    pub fn new(tor_exe: impl Into<String>) -> Self {
        Self {
            tor_exe: tor_exe.into(),
            rule_prefix: "TorTunnel".to_string(),
        }
    }

    /// `netsh` commands that engage the kill-switch (block outbound except tor).
    pub fn enable_commands(&self) -> Vec<Vec<String>> {
        vec![
            owned(&[
                "netsh",
                "advfirewall",
                "set",
                "allprofiles",
                "firewallpolicy",
                "blockinbound,blockoutbound",
            ]),
            owned(&[
                "netsh",
                "advfirewall",
                "firewall",
                "add",
                "rule",
                &format!("name={}-tor", self.rule_prefix),
                "dir=out",
                &format!("program={}", self.tor_exe),
                "action=allow",
                "enable=yes",
            ]),
            owned(&[
                "netsh",
                "advfirewall",
                "firewall",
                "add",
                "rule",
                &format!("name={}-loopback", self.rule_prefix),
                "dir=out",
                "remoteip=127.0.0.1",
                "action=allow",
                "enable=yes",
            ]),
        ]
    }

    /// `netsh` commands that disengage the kill-switch and restore outbound.
    pub fn disable_commands(&self) -> Vec<Vec<String>> {
        vec![
            owned(&[
                "netsh",
                "advfirewall",
                "firewall",
                "delete",
                "rule",
                &format!("name={}-tor", self.rule_prefix),
            ]),
            owned(&[
                "netsh",
                "advfirewall",
                "firewall",
                "delete",
                "rule",
                &format!("name={}-loopback", self.rule_prefix),
            ]),
            owned(&[
                "netsh",
                "advfirewall",
                "set",
                "allprofiles",
                "firewallpolicy",
                "blockinbound,allowoutbound",
            ]),
        ]
    }
}

pub(crate) fn owned(parts: &[&str]) -> Vec<String> {
    parts.iter().map(|part| (*part).to_string()).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn enable_blocks_outbound_and_allows_tor() {
        let ks = WindowsKillSwitch::new("C:\\Program Files\\TorTunnel\\tor.exe");
        let commands = ks.enable_commands();
        let flat: Vec<String> = commands.iter().flatten().cloned().collect();
        assert!(flat.contains(&"blockinbound,blockoutbound".to_string()));
        assert!(flat
            .iter()
            .any(|a| a.contains("program=C:\\Program Files\\TorTunnel\\tor.exe")));
        assert!(flat.iter().any(|a| a == "name=TorTunnel-tor"));
    }

    #[test]
    fn disable_restores_outbound_and_removes_rules() {
        let ks = WindowsKillSwitch::new("tor.exe");
        let commands = ks.disable_commands();
        let flat: Vec<String> = commands.iter().flatten().cloned().collect();
        assert!(flat.contains(&"blockinbound,allowoutbound".to_string()));
        assert!(flat.contains(&"delete".to_string()));
    }
}
