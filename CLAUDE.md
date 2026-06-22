# CLAUDE.md — TorTunnel

Guidance for agents working in this repository. Read this first.

## What this is

TorTunnel is a GPL-2.0-or-later, open-source, **system-wide Tor tunnel client**
for **Android, Linux, and Windows**. No accounts, no backend, local-only
diagnostics, strict leak-protection defaults.

It has three layers:

1. **Flutter UI** (`lib/`) — dark Navy/Cyan UI, EN/DE strings, responsive
   desktop/mobile layouts.
2. **Rust workspace core** (`core/`) — domain models, torrc generation, Tor
   control contracts, tunnel policy, diagnostics, leak-test contracts, and a
   versioned C ABI (FFI).
3. **Native platform adapters** — the privileged, system-wide tunnel (Android
   `VpnService`, Linux TUN+nftables helper, Windows Wintun+WFP service).

> **Status: alpha scaffold, not a production VPN.** The Flutter UI and Rust core
> are functional, but the privileged native adapters are still contracts. Strict
> Mode never reports `protected` until a platform adapter is production-ready and
> device leak tests pass. Do not weaken these fail-closed gates.

## Repo language & conventions

- **Public project → English** for all code identifiers, user-facing strings,
  and docs. (The global "private project = German output" rule does **not** apply
  here.)
- Branches: `main` (stable), `dev` (active). Releases: signed commits/tags.

## This is a native client, NOT a hosting project

The global hosting conventions (one-shot web `install.sh`, auto-update daemon,
Web-UI update stream, `doctor.sh` health endpoint) **do not apply** — there is no
server and no backend. The only systemd/polkit component is the **Linux
privileged helper** that owns TUN/nftables (see `packaging/debian`,
`packaging/rpm`). Do not bolt web-installer/auto-updater machinery onto this app.

## Build & test

```powershell
flutter pub get
flutter analyze
flutter test
```

Rust on Linux/macOS:

```bash
cargo fmt --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
cargo deny check
```

### Rust on Windows — use the wrapper

The MSVC toolchain needs (1) the MSVC `link.exe` ahead of Git's
`usr/bin/link.exe` on PATH, and (2) the **Windows SDK** in `LIB`. A plain shell
has neither, so run Cargo through `tools/dev-cargo.ps1`, which loads `vcvars64`
first:

```powershell
tools/dev-cargo.ps1 test --workspace
tools/dev-cargo.ps1 fmt --check
# Quote the `--` so PowerShell forwards it to clippy instead of consuming it:
tools/dev-cargo.ps1 clippy --workspace --all-targets '--' -D warnings
```

Install the Windows SDK once if missing:
`setup.exe modify --installPath "<VS path>" --add Microsoft.VisualStudio.Component.Windows11SDK.22621 --quiet --norestart`.

CI (`.github/workflows/ci.yml`) runs four jobs: `flutter`, `rust`, `policy`
(`cargo deny`), and `android-debug`. Keep all four green.

## How the UI talks to the core

- `lib/src/core/core_client.dart` — `CoreClient` abstract interface (the surface
  the UI depends on).
- `MockCoreClient` (`mock_core_client.dart`) — pure-Dart development core used
  when the native library is unavailable. Never claims `protected`.
- `FfiCoreClient` (`ffi_core_client.dart`) — the real Rust core over FFI. `app.dart`
  picks it via `FfiCoreClient.tryOpen()`, falling back to the mock.
- FFI bridge: Dart `TorTunnelFfiLibrary`/`FfiCoreSession` ↔ Rust C ABI
  (`core/tor_tunnel_core/src/ffi.rs`, the `tt_core_*` functions). Every call
  exchanges a JSON `FfiEnvelope { protocol_version, ok, payload, error }`.
- Build the desktop cdylib with `tools/dev-cargo.ps1 build -p tor_tunnel_core`
  (output: `target/debug/tor_tunnel_core.dll`). `test/core/ffi_core_client_test.dart`
  exercises the round-trip when that artifact exists (skips otherwise).

## Strict Mode policy (fail-closed)

TCP and DNS route through Tor; **UDP is blocked**; **IPv6 is blocked** (MVP);
exit countries are *preferences*, not guarantees; app exceptions are **forbidden**
in Strict Mode (only allowed in reduced-protection Compatibility Mode). The
kill-switch must be active before Tor bootstraps and after failures.

## Sacred paths — never break or weaken

- The fail-closed gates: `production_ready` / `SignedComponentStatus` (in
  `core/tor_tunnel_platform_contracts`) and the `protected`/leak-test gating in
  `core/tor_tunnel_core/src/lib.rs`. Only flip these after real device leak tests.
- No telemetry, no accounts, no automatic upload. Diagnostics are local and
  redacted (`core/tor_tunnel_diagnostics`).
- Future runtime secrets/state (Tor `DataDirectory`, control cookies, signing
  keys) must live outside the app bundle and never be committed.

## Roadmap & reference docs

The full restoration/vollausbau roadmap (env → green build → FFI wiring → real
Tor runtime → native adapters → leak tests/signing/audit) is tracked outside the
repo. Key in-repo references: `docs/ARCHITECTURE.md`, `docs/THREAT_MODEL.md`,
`docs/PLATFORM_ADAPTERS.md`, `docs/LEAK_TEST_MATRIX.md`,
`docs/audit/STABLE_BLOCKERS.md`. Chosen Tor engine: bundled `tor` daemon +
pluggable transports (obfs4/Snowflake) + tun2proxy TUN→SOCKS.
