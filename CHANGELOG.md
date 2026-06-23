# Changelog

All notable changes to TorTunnel are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Interactive exit-node **world map**: a tappable world map of countries that
  host Tor exit relays, plus a country list, backed by a bundled snapshot with a
  fail-closed "refresh live over Tor once connected" seam (no clearnet leak).
- Headless `tortunnel` CLI (`tortunnel-cli`) for servers and headless Linux:
  `status`, `countries`, `torrc`, `connect` (policy preview), and `doctor`.
- `CoreClient` abstraction with swappable `MockCoreClient` (pure-Dart development
  core) and `FfiCoreClient` (real Rust core over the versioned C ABI).
- Dart ⇄ Rust FFI round-trip test exercising the built cdylib.
- Tor runtime manager in `tor_tunnel_tor_manager`: ControlPort command/reply
  parsing, bootstrap-progress parsing, a testable launch plan, and a fail-closed
  `TorService` lifecycle state machine (Stopped → Starting → Bootstrapping →
  Running / Failed), driven by a fakeable launcher seam.
- `tools/dev-cargo.ps1` wrapper that runs Cargo inside the MSVC build
  environment on Windows; `rust-toolchain.toml`; `.gitattributes` line-ending
  normalization.
- Project `CLAUDE.md`, `CODE_OF_CONDUCT.md`, `CHANGELOG.md`, pull-request
  template, and Dependabot configuration.

### Fixed
- Rust core no longer compiled: removed a duplicated `derive` list on
  `FfiEnvelope<T>` (E0119) and a glob-shadowing import.
- Corrected the torrc `DNSPort` test expectation to the bound `127.0.0.1:5353`.
- Replaced two derivable `Default` impls to satisfy `clippy -D warnings`.
- Pinned internal workspace path-dependency versions so `cargo deny` passes.

### Security
- Documented and preserved the fail-closed Strict Mode gates: Strict Mode never
  reports `protected` until a native adapter is production-ready and device leak
  tests pass.

[Unreleased]: https://github.com/Elias02345/TorVPN/commits/main
