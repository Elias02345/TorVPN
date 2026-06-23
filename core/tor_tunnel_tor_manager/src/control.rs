//! Tor ControlPort protocol helpers.
//!
//! This module builds the small set of ControlPort commands TorTunnel needs and
//! parses replies. It is transport-agnostic and pure (it produces and consumes
//! strings), so it is fully unit-testable without a running tor process. The
//! caller is responsible for the actual socket I/O and for terminating each
//! command with CRLF.

/// Build an `AUTHENTICATE` command from the raw control auth cookie bytes.
///
/// Tor expects the cookie hex-encoded, e.g. `AUTHENTICATE 9f8c...`.
pub fn authenticate_with_cookie(cookie: &[u8]) -> String {
    format!("AUTHENTICATE {}", hex_encode(cookie))
}

/// `TAKEOWNERSHIP` ties the tor process lifetime to this control connection, so
/// tor exits if the controller goes away. Used together with `__OwningControllerProcess`.
pub const TAKE_OWNERSHIP: &str = "TAKEOWNERSHIP";

/// `SIGNAL NEWNYM` requests a fresh circuit / identity.
pub const SIGNAL_NEWNYM: &str = "SIGNAL NEWNYM";

/// `GETINFO status/bootstrap-phase` queries the current bootstrap progress.
pub const GETINFO_BOOTSTRAP_PHASE: &str = "GETINFO status/bootstrap-phase";

/// A parsed ControlPort reply.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ControlReply {
    /// The numeric status code (e.g. `250`, `515`, `650`).
    pub code: u16,
    /// The payload lines with status codes and separators removed.
    pub lines: Vec<String>,
}

impl ControlReply {
    /// Whether this is a `250` success reply.
    pub fn is_ok(&self) -> bool {
        self.code == 250
    }

    /// Whether this is a `650` asynchronous event.
    pub fn is_async_event(&self) -> bool {
        self.code == 650
    }
}

/// Parse a complete ControlPort reply.
///
/// Handles both single-line (`250 OK`) and multi-line (`250-...` continuation
/// lines terminated by a `250 ...` final line) replies. Returns `None` if no
/// status code can be read.
pub fn parse_reply(raw: &str) -> Option<ControlReply> {
    let mut code: Option<u16> = None;
    let mut lines = Vec::new();

    for raw_line in raw.split("\r\n").flat_map(|l| l.split('\n')) {
        let line = raw_line.trim_end_matches('\r');
        if line.is_empty() {
            continue;
        }
        // A status line is `NNN<sep><payload>` where sep is '-' (mid), '+'
        // (data), or ' ' (final).
        if line.len() >= 4 {
            let (digits, rest) = line.split_at(3);
            if let Ok(parsed) = digits.parse::<u16>() {
                let sep = rest.chars().next().unwrap_or(' ');
                if sep == '-' || sep == ' ' || sep == '+' {
                    code = Some(parsed);
                    let payload = rest[1..].to_string();
                    if !payload.is_empty() {
                        lines.push(payload);
                    }
                    continue;
                }
            }
        }
        // Continuation/data payload without a leading status code.
        lines.push(line.to_string());
    }

    code.map(|code| ControlReply { code, lines })
}

/// Extract the value of a `KEY=VALUE` pair from a reply payload line.
///
/// e.g. for `status/bootstrap-phase=NOTICE BOOTSTRAP PROGRESS=100`, asking for
/// `status/bootstrap-phase` returns `NOTICE BOOTSTRAP PROGRESS=100`.
pub fn value_for_key<'a>(reply: &'a ControlReply, key: &str) -> Option<&'a str> {
    let prefix = format!("{key}=");
    reply
        .lines
        .iter()
        .find_map(|line| line.strip_prefix(&prefix))
}

fn hex_encode(bytes: &[u8]) -> String {
    const HEX: &[u8; 16] = b"0123456789abcdef";
    let mut out = String::with_capacity(bytes.len() * 2);
    for byte in bytes {
        out.push(HEX[(byte >> 4) as usize] as char);
        out.push(HEX[(byte & 0x0f) as usize] as char);
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hex_encodes_cookie() {
        assert_eq!(
            authenticate_with_cookie(&[0x9f, 0x00, 0xab]),
            "AUTHENTICATE 9f00ab"
        );
    }

    #[test]
    fn parses_single_line_ok() {
        let reply = parse_reply("250 OK\r\n").expect("parse");
        assert_eq!(reply.code, 250);
        assert!(reply.is_ok());
        assert_eq!(reply.lines, vec!["OK".to_string()]);
    }

    #[test]
    fn parses_multi_line_reply() {
        let raw = "250-status/bootstrap-phase=NOTICE BOOTSTRAP PROGRESS=100 TAG=done\r\n250 OK\r\n";
        let reply = parse_reply(raw).expect("parse");
        assert_eq!(reply.code, 250);
        let value = value_for_key(&reply, "status/bootstrap-phase").expect("value");
        assert!(value.contains("PROGRESS=100"));
    }

    #[test]
    fn recognises_async_event() {
        let reply = parse_reply("650 STATUS_CLIENT NOTICE BOOTSTRAP PROGRESS=5").expect("parse");
        assert!(reply.is_async_event());
    }

    #[test]
    fn returns_none_without_status_code() {
        assert!(parse_reply("\r\n").is_none());
    }
}
