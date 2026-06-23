//! Headless TorTunnel CLI for servers and headless Linux.
//!
//! This is the control surface a server operator uses without a GUI. It wires the
//! shared Rust core (status, torrc generation, connection policy) to a small set
//! of subcommands. The privileged, system-wide tunnel (TUN + nftables) is a
//! Linux-only adapter that is not active yet, so `connect` previews the computed
//! policy and is explicit that no traffic is tunneled.

use std::path::PathBuf;
use std::time::Duration;

use clap::{Parser, Subcommand, ValueEnum};
use tor_tunnel_core::{
    platform_contract, BridgeConfig, ConnectionMode, ConnectionRequest, ConnectionStatus,
    CountryPreferenceMode, CountryProfile, Platform, TorConfigBuilder, TorTunnelCore,
};

mod runtime;

use runtime::{run_up, UpOptions};

/// A representative set of countries that commonly host Tor exit relays.
const KNOWN_EXIT_COUNTRIES: &[(&str, &str)] = &[
    ("DE", "Germany"),
    ("NL", "Netherlands"),
    ("SE", "Sweden"),
    ("FR", "France"),
    ("CH", "Switzerland"),
    ("US", "United States"),
    ("CA", "Canada"),
    ("GB", "United Kingdom"),
    ("FI", "Finland"),
    ("AT", "Austria"),
];

#[derive(Parser, Debug)]
#[command(
    name = "tortunnel",
    version,
    about = "Headless Tor tunnel client for servers and headless Linux"
)]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand, Debug)]
enum Command {
    /// Show the current tunnel status and platform capabilities.
    Status,
    /// List exit-country codes available to prefer.
    Countries,
    /// Print the torrc that would be generated for a country.
    Torrc {
        #[arg(long, default_value = "DE")]
        country: String,
    },
    /// Preview a connection: build the request and show the resulting policy.
    Connect {
        #[arg(long, default_value = "DE")]
        country: String,
        #[arg(long, value_enum, default_value = "strict")]
        mode: ModeArg,
    },
    /// Check the host for a headless TorTunnel deployment.
    Doctor,
    /// Launch tor and expose a working SOCKS proxy (does not capture system traffic).
    Up {
        #[arg(long, default_value = "DE")]
        country: String,
        #[arg(long, default_value = "9050")]
        socks_port: u16,
        /// Path to the tor binary (defaults to `tor` on PATH).
        #[arg(long)]
        tor_binary: Option<String>,
        /// Tor data directory (defaults to a temp directory).
        #[arg(long)]
        data_dir: Option<String>,
        /// Seconds to wait for bootstrap before giving up.
        #[arg(long, default_value = "120")]
        bootstrap_timeout: u64,
        /// Exit as soon as tor is bootstrapped (for CI / health checks).
        #[arg(long)]
        check: bool,
    },
}

#[derive(ValueEnum, Clone, Copy, Debug)]
enum ModeArg {
    Strict,
    Compatibility,
}

impl From<ModeArg> for ConnectionMode {
    fn from(mode: ModeArg) -> Self {
        match mode {
            ModeArg::Strict => ConnectionMode::Strict,
            ModeArg::Compatibility => ConnectionMode::CompatibilityReducedProtection,
        }
    }
}

fn main() {
    let cli = Cli::parse();
    match cli.command {
        Command::Status => print_status(),
        Command::Countries => print_countries(),
        Command::Torrc { country } => print_torrc(&country),
        Command::Connect { country, mode } => print_connect(&country, mode.into()),
        Command::Doctor => print_doctor(),
        Command::Up {
            country,
            socks_port,
            tor_binary,
            data_dir,
            bootstrap_timeout,
            check,
        } => run_up_command(
            &country,
            socks_port,
            tor_binary,
            data_dir,
            bootstrap_timeout,
            check,
        ),
    }
}

fn run_up_command(
    country: &str,
    socks_port: u16,
    tor_binary: Option<String>,
    data_dir: Option<String>,
    bootstrap_timeout: u64,
    check: bool,
) {
    let tor = tor_binary
        .map(PathBuf::from)
        .or_else(|| which_tor().map(PathBuf::from))
        .unwrap_or_else(|| PathBuf::from(if cfg!(windows) { "tor.exe" } else { "tor" }));
    let dir = data_dir
        .map(PathBuf::from)
        .unwrap_or_else(|| std::env::temp_dir().join("tortunnel"));
    let result = run_up(UpOptions {
        profile: profile_for(country),
        socks_port,
        tor_binary: tor,
        data_dir: dir,
        bootstrap_timeout: Duration::from_secs(bootstrap_timeout),
        check_only: check,
    });
    if let Err(err) = result {
        eprintln!("error: {err}");
        std::process::exit(1);
    }
}

fn profile_for(country: &str) -> CountryProfile {
    let code = country.trim().to_uppercase();
    let name = KNOWN_EXIT_COUNTRIES
        .iter()
        .find(|(candidate, _)| *candidate == code)
        .map(|(_, name)| (*name).to_string())
        .unwrap_or_else(|| code.clone());
    CountryProfile {
        id: format!("cli-{}", code.to_lowercase()),
        name: format!("{name} preferred"),
        exit_countries: vec![code],
        preference_mode: CountryPreferenceMode::Prefer,
    }
}

fn print_status() {
    let status = TorTunnelCore::new().status();
    println!("TorTunnel status");
    print_status_lines(&status);
    let contract = platform_contract(Platform::Linux);
    println!(
        "  Adapter: {} (production-ready: {})",
        contract.adapter_name, contract.production_ready
    );
    if !contract.production_ready {
        println!("[scaffold] The privileged Linux tunnel adapter is not active yet; no traffic is tunneled.");
    }
}

fn print_status_lines(status: &ConnectionStatus) {
    println!("  State: {:?}", status.state);
    println!("  Health: {:?}", status.health);
    println!("  Kill switch: {}", status.kill_switch_active);
    println!("  DNS over Tor: {}", status.dns_protected);
    println!("  UDP blocked: {}", status.udp_blocked);
    println!("  IPv6 blocked: {}", status.ipv6_blocked);
    println!("  Message: {}", status.message);
}

fn print_countries() {
    println!("Preferred exit countries (a preference, never a guarantee):");
    for (code, name) in KNOWN_EXIT_COUNTRIES {
        println!("  {code}  {name}");
    }
}

fn print_torrc(country: &str) {
    let config = TorConfigBuilder::new(profile_for(country)).build();
    println!("{}", config.to_torrc());
}

fn print_connect(country: &str, mode: ConnectionMode) {
    let mut core = TorTunnelCore::new();
    let request = ConnectionRequest {
        platform: Platform::Linux,
        mode,
        profile: profile_for(country),
        bridge_config: BridgeConfig::None,
        app_exceptions: Vec::new(),
        auto_fallback: true,
        isolate_by_app: true,
    };
    match core.connect(request) {
        Ok(status) => {
            println!("Connection policy computed (preview):");
            print_status_lines(&status);
            if !status.release_blockers.is_empty() {
                println!("Release blockers:");
                for blocker in &status.release_blockers {
                    println!("  - {blocker}");
                }
            }
            println!("[scaffold] No real tunnel yet: the native Linux adapter must be implemented and pass leak tests.");
        }
        Err(err) => {
            eprintln!("connect rejected: {err}");
            std::process::exit(1);
        }
    }
}

fn print_doctor() {
    println!("TorTunnel doctor (headless Linux)");
    match which_tor() {
        Some(path) => println!("  [OK]   tor binary: {path}"),
        None => println!("  [WARN] tor binary not found on PATH (a bundled tor will be required)"),
    }
    let contract = platform_contract(Platform::Linux);
    println!("  [INFO] adapter: {}", contract.adapter_name);
    println!(
        "  [{}] production-ready: {}",
        if contract.production_ready {
            "OK"
        } else {
            "PEND"
        },
        contract.production_ready
    );
    for note in &contract.native_notes {
        println!("         - {note}");
    }
}

fn which_tor() -> Option<String> {
    let exe = if cfg!(windows) { "tor.exe" } else { "tor" };
    let path_var = std::env::var_os("PATH")?;
    for dir in std::env::split_paths(&path_var) {
        let candidate = dir.join(exe);
        if candidate.is_file() {
            return Some(candidate.display().to_string());
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;
    use clap::CommandFactory;

    #[test]
    fn cli_definition_is_valid() {
        Cli::command().debug_assert();
    }

    #[test]
    fn parses_connect_with_country_and_mode() {
        let cli = Cli::try_parse_from([
            "tortunnel",
            "connect",
            "--country",
            "nl",
            "--mode",
            "compatibility",
        ])
        .expect("parse");
        match cli.command {
            Command::Connect { country, mode } => {
                assert_eq!(country, "nl");
                assert!(matches!(mode, ModeArg::Compatibility));
            }
            other => panic!("expected connect, got {other:?}"),
        }
    }

    #[test]
    fn profile_uppercases_and_names_country() {
        let profile = profile_for("de");
        assert_eq!(profile.exit_countries, vec!["DE".to_string()]);
        assert!(profile.name.contains("Germany"));
    }

    #[test]
    fn torrc_profile_contains_exit_country() {
        let config = TorConfigBuilder::new(profile_for("se")).build();
        assert!(config.to_torrc().contains("ExitNodes {SE}"));
    }
}
