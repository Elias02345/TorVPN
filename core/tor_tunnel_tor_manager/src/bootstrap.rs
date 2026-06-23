//! Parsing of Tor bootstrap progress.
//!
//! Tor reports bootstrap progress in two shapes that TorTunnel cares about:
//!
//! * Control-port async events:
//!   `650 STATUS_CLIENT NOTICE BOOTSTRAP PROGRESS=10 TAG=conn SUMMARY="Connecting"`
//! * Log notices:
//!   `Jan 01 00:00:00.000 [notice] Bootstrapped 100% (done): Done`
//!
//! Both are parsed into a single [`BootstrapStatus`]. This module is pure and
//! has no dependency on a running tor process, so it is fully unit-testable.

use serde::{Deserialize, Serialize};

/// A parsed bootstrap progress point.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BootstrapStatus {
    /// Bootstrap completion in the inclusive range `0..=100`.
    pub percent: u8,
    /// Machine-readable phase tag, e.g. `conn`, `handshake`, `done`. May be empty.
    pub tag: String,
    /// Human-readable summary, e.g. `Connecting`, `Done`. May be empty.
    pub summary: String,
}

impl BootstrapStatus {
    /// Whether Tor has finished bootstrapping.
    pub fn is_done(&self) -> bool {
        self.percent >= 100
    }
}

/// Parse a single bootstrap line from either the control port or the tor log.
///
/// Returns `None` for lines that do not carry bootstrap progress.
pub fn parse_bootstrap_progress(line: &str) -> Option<BootstrapStatus> {
    if let Some(status) = parse_control_event(line) {
        return Some(status);
    }
    parse_log_notice(line)
}

/// Parse the `PROGRESS=NN TAG=xxx SUMMARY="..."` control-event form.
fn parse_control_event(line: &str) -> Option<BootstrapStatus> {
    let progress = extract_key(line, "PROGRESS=")?;
    let percent = clamp_percent(progress.parse::<i32>().ok()?);
    let tag = extract_key(line, "TAG=").unwrap_or_default();
    let summary = extract_quoted(line, "SUMMARY=").unwrap_or_default();
    Some(BootstrapStatus {
        percent,
        tag,
        summary,
    })
}

/// Parse the `Bootstrapped NN% (tag): summary` log-notice form.
fn parse_log_notice(line: &str) -> Option<BootstrapStatus> {
    let idx = line.find("Bootstrapped ")?;
    let rest = &line[idx + "Bootstrapped ".len()..];
    let percent_str: String = rest.chars().take_while(|c| c.is_ascii_digit()).collect();
    if percent_str.is_empty() {
        return None;
    }
    let percent = clamp_percent(percent_str.parse::<i32>().ok()?);

    let tag = rest
        .split_once('(')
        .and_then(|(_, after)| after.split_once(')'))
        .map(|(tag, _)| tag.trim().to_string())
        .unwrap_or_default();

    let summary = rest
        .split_once(':')
        .map(|(_, after)| after.trim().to_string())
        .unwrap_or_default();

    Some(BootstrapStatus {
        percent,
        tag,
        summary,
    })
}

/// Extract a whitespace-delimited `key=value` token's value.
fn extract_key(line: &str, key: &str) -> Option<String> {
    let start = line.find(key)? + key.len();
    let rest = &line[start..];
    let value: String = rest
        .chars()
        .take_while(|c| !c.is_whitespace() && *c != '"')
        .collect();
    if value.is_empty() {
        None
    } else {
        Some(value)
    }
}

/// Extract a `key="quoted value"` token's value.
fn extract_quoted(line: &str, key: &str) -> Option<String> {
    let start = line.find(key)? + key.len();
    let rest = &line[start..];
    let rest = rest.strip_prefix('"')?;
    let end = rest.find('"')?;
    Some(rest[..end].to_string())
}

fn clamp_percent(value: i32) -> u8 {
    value.clamp(0, 100) as u8
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_control_event_with_quoted_summary() {
        let line = r#"650 STATUS_CLIENT NOTICE BOOTSTRAP PROGRESS=10 TAG=conn SUMMARY="Connecting to a relay""#;
        let status = parse_bootstrap_progress(line).expect("should parse");
        assert_eq!(status.percent, 10);
        assert_eq!(status.tag, "conn");
        assert_eq!(status.summary, "Connecting to a relay");
        assert!(!status.is_done());
    }

    #[test]
    fn parses_log_notice_done() {
        let line = "Jan 01 00:00:00.000 [notice] Bootstrapped 100% (done): Done";
        let status = parse_bootstrap_progress(line).expect("should parse");
        assert_eq!(status.percent, 100);
        assert_eq!(status.tag, "done");
        assert_eq!(status.summary, "Done");
        assert!(status.is_done());
    }

    #[test]
    fn clamps_out_of_range_progress() {
        let line = "650 STATUS_CLIENT NOTICE BOOTSTRAP PROGRESS=250 TAG=done";
        let status = parse_bootstrap_progress(line).expect("should parse");
        assert_eq!(status.percent, 100);
    }

    #[test]
    fn ignores_unrelated_lines() {
        assert!(parse_bootstrap_progress("250 OK").is_none());
        assert!(parse_bootstrap_progress("random log line").is_none());
    }
}
