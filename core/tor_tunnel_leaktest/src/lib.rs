use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum LeakCheckKind {
    Ip,
    Dns,
    Udp,
    Ipv6,
    KillSwitch,
    Onion,
    Bridge,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum LeakCheckStatus {
    NotRun,
    Passed,
    Failed,
    Blocked,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LeakCheckResult {
    pub kind: LeakCheckKind,
    pub status: LeakCheckStatus,
    pub message: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LeakSelfTestReport {
    pub strict_mode: bool,
    pub stable_release_allowed: bool,
    pub results: Vec<LeakCheckResult>,
}

impl LeakSelfTestReport {
    pub fn preflight_blocked(reason: &str) -> Self {
        Self {
            strict_mode: true,
            stable_release_allowed: false,
            results: vec![
                LeakCheckResult {
                    kind: LeakCheckKind::Ip,
                    status: LeakCheckStatus::Blocked,
                    message: reason.to_string(),
                },
                LeakCheckResult {
                    kind: LeakCheckKind::Dns,
                    status: LeakCheckStatus::Blocked,
                    message: reason.to_string(),
                },
                LeakCheckResult {
                    kind: LeakCheckKind::Udp,
                    status: LeakCheckStatus::Blocked,
                    message: reason.to_string(),
                },
                LeakCheckResult {
                    kind: LeakCheckKind::Ipv6,
                    status: LeakCheckStatus::Blocked,
                    message: reason.to_string(),
                },
                LeakCheckResult {
                    kind: LeakCheckKind::KillSwitch,
                    status: LeakCheckStatus::Blocked,
                    message: reason.to_string(),
                },
            ],
        }
    }
}
