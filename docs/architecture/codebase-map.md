# TorTunnel Codebase Map

Generated after `graphify build .` on 2026-06-11.

Graphify indexed 100 files, 184 symbols, and 167 relationships.

## Runtime Shape

TorTunnel is a Flutter app shell backed by a Rust workspace:

- `lib/src/app.dart` owns the adaptive app shell and creates a `CoreClient`.
- `lib/src/core/core_client.dart` is the UI boundary. Screens depend on this interface, not on the mock implementation.
- `lib/src/core/mock_core_client.dart` is the alpha/development client. It is fail-closed and locks real connection start until evidence gates pass.
- `lib/src/core/ffi_core_client.dart` owns the Dart FFI session and versioned JSON envelope calls into `tor_tunnel_core`.
- `core/tor_tunnel_core` owns connection state, torrc generation, diagnostics, release readiness, and the C ABI.
- `core/tor_tunnel_platform_contracts` describes Android, Linux, and Windows adapter capabilities and blockers.

## UI Flow

The app uses five primary destinations:

- Home: consumer-friendly readiness overview, locked connect control, setup steps, platform readiness, and advanced evidence.
- Countries: exit-country preferences with explicit fallback and no location guarantee.
- App exceptions: disabled in Strict Mode; visible reduced-protection behavior in Compatibility Mode.
- Evidence: leak matrix, claim evidence, local diagnostics, exit verification, and leak self-test.
- Settings: mode, bridges, language, diagnostics, release gate status, and audit blockers.

## Trust Boundaries

- User-facing protection claims must come from `ProtectionClaim` or `LeakEvidenceItem` records with an `evidenceId`.
- `ReleaseReadiness.canAttemptRealConnection` is the app-level gate for a real connect action.
- Native adapter TODOs remain unavailable states until platform-specific evidence changes them.
- Strict Mode cannot display `protected` while adapter readiness, leak tests, signing, or audit blockers remain open.
- Blocked/disconnected scaffold states do not report DNS, UDP, or IPv6 protection as verified facts.

## Rust Workspace Map

- `tor_tunnel_core`: orchestration, state, FFI, readiness, diagnostics, torrc preview.
- `tor_tunnel_tor_manager`: bridge and Tor runtime configuration contracts.
- `tor_tunnel_tunnel_engine`: strict packet policy decisions for TCP, DNS, UDP, IPv6, and direct fallback.
- `tor_tunnel_platform_contracts`: platform capabilities and production blockers.
- `tor_tunnel_diagnostics`: redaction and local diagnostic bundle model.
- `tor_tunnel_leaktest`: leak self-test result contract.

## Native Adapter Map

- Android: `android/app/src/main/kotlin/org/tortunnel/tortunnel/TorTunnelVpnService.kt` establishes a scaffold `VpnService` and deliberately avoids bypass/IPv6 in Strict Mode.
- Linux: packaging contracts exist for helper/service policy, but the privileged TUN/nftables helper is not production-ready.
- Windows: packaging contracts mention Wintun/WFP, but signing/legal review and service implementation remain blockers.

## Verification Gates

Required before any stable release:

- Flutter analyzer and widget tests.
- Rust fmt, clippy, tests, and cargo-deny.
- Device/VM leak matrix for Exit IP, DNS, IPv6, UDP, kill-switch, network changes, sleep/resume, app exceptions, fallback, and diagnostics.
- Signing, packaging provenance, Wintun review, and external audit evidence.
