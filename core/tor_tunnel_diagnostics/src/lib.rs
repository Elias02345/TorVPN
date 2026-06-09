use serde::{Deserialize, Serialize};
use tor_tunnel_platform_contracts::Platform;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RedactionPolicy {
    pub redact_ips: bool,
    pub redact_hostnames: bool,
    pub redact_paths: bool,
    pub include_torrc_preview: bool,
}

impl Default for RedactionPolicy {
    fn default() -> Self {
        Self {
            redact_ips: true,
            redact_hostnames: true,
            redact_paths: true,
            include_torrc_preview: false,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DiagnosticBundle {
    pub generated_at_unix: u64,
    pub app_version: String,
    pub platform: Option<Platform>,
    pub health: String,
    pub redacted_logs: Vec<String>,
    pub tor_config_preview: Option<String>,
    pub release_blockers: Vec<String>,
}

pub fn redact_log_line(line: &str, policy: &RedactionPolicy) -> String {
    let mut value = line.to_string();
    if policy.redact_ips {
        value = redact_ipv4_like(&value);
    }
    if policy.redact_paths {
        value = value.replace('\\', "/");
    }
    value
}

fn redact_ipv4_like(input: &str) -> String {
    input
        .split_whitespace()
        .map(|part| {
            let dot_count = part.matches('.').count();
            if dot_count == 3 && part.chars().all(|ch| ch.is_ascii_digit() || ch == '.') {
                "[redacted-ip]"
            } else {
                part
            }
        })
        .collect::<Vec<_>>()
        .join(" ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn redacts_ipv4_addresses() {
        let policy = RedactionPolicy::default();
        assert_eq!(
            redact_log_line("exit 185.220.101.42 connected", &policy),
            "exit [redacted-ip] connected"
        );
    }
}
