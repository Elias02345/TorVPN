# Releases

## Channels

- Android: GitHub Releases and F-Droid.
- Linux: Flatpak and AppImage first.
- Windows: signed installer through GitHub Releases.

## Release Gates

- All CI checks pass.
- Release artifacts are signed.
- Tor binary/source provenance is documented.
- Leak-test matrix passes on each supported platform.
- Security policy and threat model are current.
- Stable blockers in `docs/audit/STABLE_BLOCKERS.md` are all closed.
- Compatibility Mode can never display the same protected status as Strict Mode.

## Signing Placeholder

The CI workflow includes release gates but not production signing keys. Production signing keys must not be committed to this repository. Use GitHub Actions secrets or an offline release process.
