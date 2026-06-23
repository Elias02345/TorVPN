# Contributing

TorTunnel accepts contributions that preserve the privacy model: no backend requirement, no telemetry, no account dependency, and no hidden traffic fallback outside Tor.

## Development Standards

- Keep platform tunnel changes behind explicit Android, Linux, or Windows adapters.
- Do not weaken kill-switch, DNS, UDP, or IPv6 policy without updating the threat model and leak-test matrix.
- Keep app exceptions out of Strict Mode. Compatibility Mode must be visibly marked as reduced protection.
- Prefer small, testable changes with platform-specific acceptance notes.

## Checks

Run the full gate before opening a pull request (the same jobs CI runs):

```bash
flutter analyze
flutter test
cargo fmt --check
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace
cargo deny check
```

On Windows, run the Cargo commands through `tools/dev-cargo.ps1` so the MSVC
linker and Windows SDK are on the path — see the
[README build notes](README.md#building-on-windows) and [`CLAUDE.md`](CLAUDE.md).

## Documentation

Update docs when changing public behavior, threat assumptions, platform routing, release signing, or diagnostics.
