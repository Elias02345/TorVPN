//! Privileged Linux helper that builds the system-wide Tor tunnel.
//!
//! Run by the systemd/polkit unit (see `packaging/`). It applies the nftables
//! kill-switch, creates the TUN device, runs tor and `tun2proxy`, and tears
//! everything down on stop. The UI stays unprivileged and talks to this helper.
//!
//! The pure planning lives in [`plan`]; this file only executes it. As with
//! every TorTunnel adapter it is fail-closed and **must pass the device
//! leak-test matrix** (see `docs/VERIFICATION_CHECKLIST.md`) before it can be
//! trusted to provide anonymity.

mod plan;

use std::io::Write;
use std::path::PathBuf;
use std::process;
use std::process::Stdio;

use clap::{Parser, Subcommand};
use tor_tunnel_core::{CountryPreferenceMode, CountryProfile, TorConfigBuilder};

use plan::TunnelPlan;

#[derive(Parser, Debug)]
#[command(
    name = "tortunnel-helper",
    version,
    about = "Privileged Linux helper that builds the system-wide Tor tunnel"
)]
struct Cli {
    #[command(subcommand)]
    command: Action,
}

#[derive(Subcommand, Debug)]
enum Action {
    /// Bring up the system tunnel (root): nftables kill-switch + TUN + tor + tun2proxy.
    Up {
        #[arg(long, default_value = "DE")]
        country: String,
        /// User tor drops privileges to (its uid must match --tor-uid).
        #[arg(long, default_value = "debian-tor")]
        tor_user: String,
        /// uid the nftables kill-switch allows out (tor's uid).
        #[arg(long, default_value = "108")]
        tor_uid: u32,
        #[arg(long)]
        tor_binary: Option<String>,
        #[arg(long)]
        tun2proxy_binary: Option<String>,
        #[arg(long, default_value = "/var/lib/tortunnel")]
        data_dir: String,
    },
    /// Tear down the system tunnel (root): remove the nftables table and TUN device.
    Down {
        #[arg(long, default_value = "tortun0")]
        tun_name: String,
    },
    /// Print the nftables kill-switch that `up` would apply (no privileges needed).
    PrintNft {
        #[arg(long, default_value = "108")]
        tor_uid: u32,
        #[arg(long, default_value = "tortun0")]
        tun_name: String,
    },
}

fn main() {
    let cli = Cli::parse();
    let result = match cli.command {
        Action::Up {
            country,
            tor_user,
            tor_uid,
            tor_binary,
            tun2proxy_binary,
            data_dir,
        } => cmd_up(
            &country,
            &tor_user,
            tor_uid,
            tor_binary,
            tun2proxy_binary,
            &data_dir,
        ),
        Action::Down { tun_name } => cmd_down(&tun_name),
        Action::PrintNft { tor_uid, tun_name } => {
            use tor_tunnel_tunnel_engine::KillSwitchPlan;
            println!("{}", KillSwitchPlan::strict(tun_name, tor_uid).render());
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
    tor_user: &str,
    tor_uid: u32,
    tor_binary: Option<String>,
    tun2proxy_binary: Option<String>,
    data_dir: &str,
) -> Result<(), String> {
    require_linux_root()?;
    let plan = TunnelPlan::strict_default(country, tor_uid);
    let data = PathBuf::from(data_dir);
    std::fs::create_dir_all(&data).map_err(|err| format!("create data dir: {err}"))?;

    // 1. tor (drops to tor_user so its outbound matches the kill-switch uid).
    let profile = profile_for(country);
    let torrc = format!(
        "Log notice stdout\nUser {tor_user}\n{}\n",
        TorConfigBuilder::new(profile)
            .socks_port(plan.socks_port)
            .build()
            .to_torrc()
    );
    let torrc_path = data.join("torrc");
    std::fs::write(&torrc_path, torrc).map_err(|err| format!("write torrc: {err}"))?;
    let tor_bin = tor_binary.unwrap_or_else(|| "tor".to_string());
    let mut tor = process::Command::new(&tor_bin)
        .arg("-f")
        .arg(&torrc_path)
        .arg("--DataDirectory")
        .arg(&data)
        .spawn()
        .map_err(|err| format!("failed to launch tor ({tor_bin}): {err}"))?;

    // 2. kill-switch before anything else can leak.
    apply_nft(&plan.nftables())?;

    // 3. TUN device + default route.
    run_all(plan.tun_setup_commands(), false)?;

    // 4. tun2proxy bridges the TUN to tor's SOCKS port.
    let t2p_bin = tun2proxy_binary.unwrap_or_else(|| "tun2proxy".to_string());
    let mut tun2proxy = process::Command::new(&t2p_bin)
        .args(plan.tun2proxy_args())
        .spawn()
        .map_err(|err| format!("failed to launch tun2proxy ({t2p_bin}): {err}"))?;

    println!(
        "System tunnel up: TCP/DNS routed through Tor via {} (exit preference {}).",
        plan.tun_name, plan.exit_country
    );

    // Run until tun2proxy exits, then fail-closed tear down.
    let _ = tun2proxy.wait();
    teardown(&plan);
    let _ = tor.kill();
    let _ = tor.wait();
    Ok(())
}

fn cmd_down(tun_name: &str) -> Result<(), String> {
    require_linux_root()?;
    let plan = TunnelPlan {
        tun_name: tun_name.to_string(),
        ..TunnelPlan::strict_default("DE", 108)
    };
    teardown(&plan);
    Ok(())
}

fn teardown(plan: &TunnelPlan) {
    // Best-effort: remove the nftables table and the TUN device.
    let _ = process::Command::new("nft")
        .args(["delete", "table", "inet", "tortunnel"])
        .status();
    let _ = run_all(plan.tun_teardown_commands(), true);
}

fn apply_nft(ruleset: &str) -> Result<(), String> {
    let mut child = process::Command::new("nft")
        .arg("-f")
        .arg("-")
        .stdin(Stdio::piped())
        .spawn()
        .map_err(|err| format!("failed to run nft: {err}"))?;
    child
        .stdin
        .take()
        .ok_or_else(|| "nft has no stdin".to_string())?
        .write_all(ruleset.as_bytes())
        .map_err(|err| format!("writing nft ruleset: {err}"))?;
    let status = child.wait().map_err(|err| format!("nft wait: {err}"))?;
    if !status.success() {
        return Err("nft failed to apply the kill-switch ruleset".to_string());
    }
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

fn require_linux_root() -> Result<(), String> {
    if !cfg!(target_os = "linux") {
        return Err("the privileged tunnel helper runs on Linux only".to_string());
    }
    let output = process::Command::new("id")
        .arg("-u")
        .output()
        .map_err(|err| format!("could not determine uid: {err}"))?;
    if String::from_utf8_lossy(&output.stdout).trim() != "0" {
        return Err("must run as root (use the systemd/polkit helper unit)".to_string());
    }
    Ok(())
}

fn profile_for(country: &str) -> CountryProfile {
    let code = country.trim().to_uppercase();
    CountryProfile {
        id: format!("helper-{}", code.to_lowercase()),
        name: format!("{code} preferred"),
        exit_countries: vec![code],
        preference_mode: CountryPreferenceMode::Prefer,
    }
}
