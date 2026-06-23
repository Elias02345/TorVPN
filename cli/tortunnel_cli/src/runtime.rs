//! Runtime that launches a real `tor` process and exposes a SOCKS proxy.
//!
//! This is the first genuinely functional capability: it writes a torrc, starts
//! tor, follows its bootstrap on stdout, and reports a working SOCKS proxy at
//! `127.0.0.1:<port>`. It does **not** capture system-wide traffic — that is the
//! privileged TUN/nftables adapter (Linux) and is a separate, device-verified
//! step. Applications must be pointed at the SOCKS proxy explicitly.

use std::io::{BufRead, BufReader};
use std::path::PathBuf;
use std::process::{Command, Stdio};
use std::sync::mpsc;
use std::thread;
use std::time::{Duration, Instant};

use tor_tunnel_core::{CountryProfile, TorConfigBuilder};
use tor_tunnel_tor_manager::parse_bootstrap_progress;

/// Options for [`run_up`].
pub struct UpOptions {
    pub profile: CountryProfile,
    pub socks_port: u16,
    pub tor_binary: PathBuf,
    pub data_dir: PathBuf,
    pub bootstrap_timeout: Duration,
    /// Exit as soon as tor is bootstrapped (used by CI); otherwise run until tor exits.
    pub check_only: bool,
}

/// Build the torrc text used for a SOCKS-proxy run. Pure, so it is unit-testable.
pub fn render_socks_torrc(profile: CountryProfile, socks_port: u16) -> String {
    let config = TorConfigBuilder::new(profile)
        .socks_port(socks_port)
        .build();
    format!("Log notice stdout\n{}\n", config.to_torrc())
}

/// Launch tor and follow it to a bootstrapped SOCKS proxy.
pub fn run_up(options: UpOptions) -> Result<(), String> {
    std::fs::create_dir_all(&options.data_dir)
        .map_err(|err| format!("could not create data directory: {err}"))?;

    let torrc_path = options.data_dir.join("torrc");
    std::fs::write(
        &torrc_path,
        render_socks_torrc(options.profile.clone(), options.socks_port),
    )
    .map_err(|err| format!("could not write torrc: {err}"))?;

    let mut child = Command::new(&options.tor_binary)
        .arg("-f")
        .arg(&torrc_path)
        .arg("--DataDirectory")
        .arg(&options.data_dir)
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .map_err(|err| {
            format!(
                "failed to launch tor ({}): {err}",
                options.tor_binary.display()
            )
        })?;

    let stdout = child
        .stdout
        .take()
        .ok_or_else(|| "tor produced no stdout".to_string())?;

    let (tx, rx) = mpsc::channel::<String>();
    thread::spawn(move || {
        for line in BufReader::new(stdout).lines().map_while(Result::ok) {
            if tx.send(line).is_err() {
                break;
            }
        }
    });

    let deadline = Instant::now() + options.bootstrap_timeout;
    let mut bootstrapped = false;
    while Instant::now() < deadline {
        match rx.recv_timeout(Duration::from_millis(500)) {
            Ok(line) => {
                if let Some(status) = parse_bootstrap_progress(&line) {
                    println!("[{:>3}%] {}", status.percent, status.summary);
                    if status.is_done() {
                        bootstrapped = true;
                        break;
                    }
                }
            }
            Err(mpsc::RecvTimeoutError::Timeout) => {
                if let Ok(Some(exit)) = child.try_wait() {
                    return Err(format!("tor exited early ({exit})"));
                }
            }
            Err(mpsc::RecvTimeoutError::Disconnected) => break,
        }
    }

    if !bootstrapped {
        let _ = child.kill();
        let _ = child.wait();
        return Err("tor did not finish bootstrapping before the timeout".to_string());
    }

    println!(
        "Tor is bootstrapped. SOCKS proxy ready at socks5://127.0.0.1:{}",
        options.socks_port
    );
    println!(
        "Point applications at this proxy (e.g. curl --socks5-hostname 127.0.0.1:{}).",
        options.socks_port
    );

    if options.check_only {
        let _ = child.kill();
        let _ = child.wait();
        return Ok(());
    }

    println!("Press Ctrl-C to stop tor.");
    let exit = child
        .wait()
        .map_err(|err| format!("waiting on tor failed: {err}"))?;
    if !exit.success() {
        return Err(format!("tor exited with {exit}"));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use tor_tunnel_core::CountryPreferenceMode;

    fn profile() -> CountryProfile {
        CountryProfile {
            id: "test".to_string(),
            name: "Test".to_string(),
            exit_countries: vec!["DE".to_string()],
            preference_mode: CountryPreferenceMode::Prefer,
        }
    }

    #[test]
    fn torrc_logs_to_stdout_and_sets_socks_port() {
        let torrc = render_socks_torrc(profile(), 9150);
        assert!(torrc.starts_with("Log notice stdout"));
        assert!(torrc.contains("SocksPort 127.0.0.1:9150"));
        assert!(torrc.contains("ExitNodes {DE}"));
    }

    #[test]
    fn missing_tor_binary_fails_closed() {
        let result = run_up(UpOptions {
            profile: profile(),
            socks_port: 9150,
            tor_binary: PathBuf::from("definitely-not-a-real-tor-binary"),
            data_dir: std::env::temp_dir().join("tortunnel-test-missing"),
            bootstrap_timeout: Duration::from_secs(1),
            check_only: true,
        });
        assert!(result.is_err());
    }
}
