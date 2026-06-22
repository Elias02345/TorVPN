# TorTunnel

TorTunnel is a GPL-2.0-or-later open-source Tor tunnel client for Android, Linux, and Windows. It is designed as a system-wide Tor tunnel with country preferences, strict leak-protection defaults, no accounts, no backend, and local-only diagnostics.

This repository currently implements the foundation and product alpha scaffold plus production-facing contracts:

- Flutter app shell with dark Navy/Cyan UI, German/English strings, and responsive Android/Desktop layouts.
- Rust workspace crates with shared models, Tor configuration generation, platform tunnel contracts, diagnostic export, leak-test contracts, and a C ABI surface.
- Explicit native adapter contracts for Android `VpnService`, Linux TUN/nftables, and Windows Wintun/WFP.
- Threat model, leak-test matrix, security policy, contribution guide, and CI.

## Important Status

The app is not a production VPN yet. The Rust core and Flutter UI are functional scaffolds with fail-closed contracts, but the privileged platform tunnel adapters still need real native implementation, signing, device leak tests, and an external audit before public stable use.

Strict Mode policy:

- TCP and DNS are intended to route through Tor.
- UDP is blocked by default.
- IPv6 is blocked in the MVP.
- Exit countries are preferences, not strict guarantees.
- P2P/torrenting is warned against and not a supported use case.
- App exceptions are forbidden in Strict Mode and only exist in a reduced-protection compatibility mode.
- Diagnostics are local and manually exported only.

## Repository Layout

```text
core/tor_tunnel_core/   Rust domain core, torrc builder, FFI contracts
core/tor_tunnel_*/      Tor manager, tunnel engine, platform, diagnostics, leak-test contracts
lib/                    Flutter UI and mock core client
android/                Flutter Android runner and VpnService contract
linux/                  Flutter Linux runner
windows/                Flutter Windows runner
docs/                   Architecture, threat model, leak tests
packaging/              Flatpak, AppImage, DEB/RPM, and Windows release contracts
```

## Development

```powershell
flutter pub get
flutter test
flutter analyze
cargo test
```

### Building on Windows

The Rust `*-pc-windows-msvc` toolchain needs the **Visual Studio C++ build tools**
*and* the **Windows SDK** (`kernel32.lib` and friends). It also requires the MSVC
`link.exe` to win over Git's `usr/bin/link.exe`, which otherwise shadows it on PATH.

A normal PowerShell session provides neither, so run Cargo through the bundled
wrapper, which loads the `vcvars64` environment first and forwards all arguments
to `cargo`:

```powershell
tools/dev-cargo.ps1 build --workspace
tools/dev-cargo.ps1 test --workspace
tools/dev-cargo.ps1 fmt --check
# Quote the `--` separator so PowerShell forwards it instead of consuming it:
tools/dev-cargo.ps1 clippy --workspace --all-targets '--' -D warnings
```

If the Windows SDK is missing, install it once via the Visual Studio Installer:

```powershell
& "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\setup.exe" modify `
  --installPath "C:\Program Files\Microsoft Visual Studio\2022\Community" `
  --add Microsoft.VisualStudio.Component.Windows11SDK.22621 --quiet --norestart
```

Linux and macOS can call `cargo` directly.

## License

TorTunnel is licensed under GPL-2.0-or-later. See [LICENSE](LICENSE).
