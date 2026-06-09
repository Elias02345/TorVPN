# Architecture

TorTunnel has three layers:

1. Flutter UI for Android, Linux, and Windows.
2. Rust workspace for state, Tor control contracts, torrc generation, tunnel policy, diagnostics, leak tests, and FFI.
3. Native platform adapters for the actual system-wide tunnel.

## Flutter Layer

The current app runs against a development core client that mirrors the Rust core surface while native packaging is unfinished. The production path is Dart FFI through `TorTunnelFfiLibrary` and the versioned C ABI exported by `tor_tunnel_core`.

Primary screens:

- Home: connection status, profile selection, leak-protection status.
- Countries: preferred exit profiles and relay availability.
- App exceptions: disabled in Strict Mode; deliberate reduced-protection bypasses in Compatibility Mode only.
- Activity: exit verification, circuit actions, local diagnostics.
- Settings: auto-connect, language, diagnostic verbosity, trust policy.

## Rust Core

The Rust crate owns shared product behavior:

- `CountryProfile`
- `ConnectionRequest`
- `ConnectionStatus`
- `AppException`
- `RelayCountryStatus`
- `DiagnosticBundle`

Core commands:

- `connect(profile)`
- `disconnect()`
- `rotate_identity()`
- `set_app_exceptions()`
- `verify_exit()`
- `export_diagnostics()`

## Native Adapters

Android uses a foreground `VpnService`. Linux needs a privileged helper for TUN, nftables, DNS policy, and kill-switch rules. Windows needs a signed service with Wintun and Windows Filtering Platform rules.

Adapters are not production-ready until they enforce:

- TCP routed through Tor.
- DNS handled through Tor.
- UDP blocked in MVP.
- IPv6 blocked in MVP.
- Kill-switch active before Tor bootstraps and after failures.
- App exceptions only when they preserve explicit user intent and documented risk.

Strict Mode cannot show `protected` until the platform adapter reports production-ready capabilities and device leak tests pass.
