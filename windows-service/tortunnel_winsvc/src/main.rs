//! Windows service that builds the system-wide Tor tunnel.
//!
//! Mirrors the Linux helper: a Wintun adapter (created by `tun2proxy`) carries
//! traffic to tor's SOCKS port, and a WFP-backed kill-switch (via the Windows
//! firewall) blocks all direct outbound except tor. The pure WFP policy lives in
//! [`firewall`]; this file orchestrates tor + `tun2proxy` and applies the policy.
//!
//! Fail-closed and **must pass the device leak-test matrix**
//! (see `docs/VERIFICATION_CHECKLIST.md`) before it can be trusted.

mod firewall;

use std::path::PathBuf;
use std::process;
use std::process::Stdio;

use clap::{Parser, Subcommand};
use tor_tunnel_core::{CountryPreferenceMode, CountryProfile, TorConfigBuilder};

use firewall::WindowsKillSwitch;

#[derive(Parser, Debug)]
#[command(
    name = "tortunnel-winsvc",
    version,
    about = "Windows service that builds the system-wide Tor tunnel (Wintun + WFP)"
)]
struct Cli {
    #[command(subcommand)]
    command: Action,
}

#[derive(Subcommand, Debug)]
enum Action {
    /// Bring up the tunnel (Administrator): WFP kill-switch + tor + tun2proxy.
    Up {
        #[arg(long, default_value = "DE")]
        country: String,
        #[arg(long, default_value = "tor.exe")]
        tor_binary: String,
        #[arg(long, default_value = "tun2proxy.exe")]
        tun2proxy_binary: String,
        #[arg(long)]
        data_dir: Option<String>,
        #[arg(long, default_value = "9050")]
        socks_port: u16,
    },
    /// Tear down the tunnel (Administrator): restore outbound and remove rules.
    Down {
        #[arg(long, default_value = "tor.exe")]
        tor_binary: String,
    },
    /// Print the WFP kill-switch commands that `up` would apply.
    PrintPlan {
        #[arg(long, default_value = "tor.exe")]
        tor_binary: String,
    },
}

fn main() {
    let cli = Cli::parse();
    let result = match cli.command {
        Action::Up {
            country,
            tor_binary,
            tun2proxy_binary,
            data_dir,
            socks_port,
        } => cmd_up(
            &country,
            &tor_binary,
            &tun2proxy_binary,
            data_dir,
            socks_port,
        ),
        Action::Down { tor_binary } => cmd_down(&tor_binary),
        Action::PrintPlan { tor_binary } => {
            for command in WindowsKillSwitch::new(&tor_binary).enable_commands() {
                println!("{}", command.join(" "));
            }
            Ok(())
        }
    };
    if let Err(err) = result {
        eprintln!("error: {err}");
        process::exit(1);
    }
}

fn cmd_up(
    country: &str,
    tor_binary: &str,
    tun2proxy_binary: &str,
    data_dir: Option<String>,
    socks_port: u16,
) -> Result<(), String> {
    require_windows_admin()?;
    let data = data_dir
        .map(PathBuf::from)
        .unwrap_or_else(|| std::env::temp_dir().join("tortunnel"));
    std::fs::create_dir_all(&data).map_err(|err| format!("create data dir: {err}"))?;

    // 1. tor (SOCKS proxy).
    let torrc = format!(
        "Log notice stdout\n{}\n",
        TorConfigBuilder::new(profile_for(country))
            .socks_port(socks_port)
            .build()
            .to_torrc()
    );
    let torrc_path = data.join("torrc");
    std::fs::write(&torrc_path, torrc).map_err(|err| format!("write torrc: {err}"))?;
    let mut tor = process::Command::new(tor_binary)
        .arg("-f")
        .arg(&torrc_path)
        .arg("--DataDirectory")
        .arg(&data)
        .spawn()
        .map_err(|err| format!("failed to launch tor ({tor_binary}): {err}"))?;

    // 2. WFP kill-switch before anything can leak.
    let kill_switch = WindowsKillSwitch::new(tor_binary);
    run_all(kill_switch.enable_commands(), false)?;

    // 3. tun2proxy creates the Wintun adapter and forwards to tor's SOCKS.
    let mut tun2proxy = process::Command::new(tun2proxy_binary)
        .args([
            "--proxy".to_string(),
            format!("socks5://127.0.0.1:{socks_port}"),
        ])
        .spawn()
        .map_err(|err| format!("failed to launch tun2proxy ({tun2proxy_binary}): {err}"))?;

    println!("Windows system tunnel up (Wintun + WFP kill-switch, exit preference {country}).");

    let _ = tun2proxy.wait();
    let _ = run_all(kill_switch.disable_commands(), true);
    let _ = tor.kill();
    let _ = tor.wait();
    Ok(())
}

fn cmd_down(tor_binary: &str) -> Result<(), String> {
    require_windows_admin()?;
    let _ = run_all(WindowsKillSwitch::new(tor_binary).disable_commands(), true);
    Ok(())
}

fn run_all(commands: Vec<Vec<String>>, ignore_errors: bool) -> Result<(), String> {
    for command in commands {
        let (program, args) = command.split_first().ok_or("empty command")?;
        let status = process::Command::new(program).args(args).status();
        let ok = matches!(status, Ok(status) if status.success());
        if !ok && !ignore_errors {
            return Err(format!("command failed: {}", command.join(" ")));
        }
    }
    Ok(())
}

fn require_windows_admin() -> Result<(), String> {
    if !cfg!(windows) {
        return Err("the Windows tunnel service runs on Windows only".to_string());
    }
    // `net session` succeeds only for an elevated (Administrator) context.
    let status = process::Command::new("net")
        .arg("session")
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();
    match status {
        Ok(status) if status.success() => Ok(()),
        _ => Err("must run as Administrator".to_string()),
    }
}

fn profile_for(country: &str) -> CountryProfile {
    let code = country.trim().to_uppercase();
    CountryProfile {
        id: format!("winsvc-{}", code.to_lowercase()),
        name: format!("{code} preferred"),
        exit_countries: vec![code],
        preference_mode: CountryPreferenceMode::Prefer,
    }
}
