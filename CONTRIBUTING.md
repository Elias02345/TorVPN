# Contributing

TorTunnel accepts contributions that preserve the privacy model: no backend requirement, no telemetry, no account dependency, and no hidden traffic fallback outside Tor.

## Development Standards

- Keep platform tunnel changes behind explicit Android, Linux, or Windows adapters.
- Do not weaken kill-switch, DNS, UDP, or IPv6 policy without updating the threat model and leak-test matrix.
- Keep app exceptions out of Strict Mode. Compatibility Mode must be visibly marked as reduced protection.
- Prefer small, testable changes with platform-specific acceptance notes.

## Checks

Run the relevant checks before opening a pull request:

```powershell
flutter test
flutter analyze
cargo test
```

## Documentation

Update docs when changing public behavior, threat assumptions, platform routing, release signing, or diagnostics.
