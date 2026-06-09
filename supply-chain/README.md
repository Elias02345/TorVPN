# Supply Chain Gates

Stable releases require:

- `cargo deny check`
- `cargo audit`
- `cargo vet`
- SBOM generation for Rust, Flutter, Android, Linux packages, and Windows MSI
- Signed artifacts with published SHA-256 checksums
- Pinned, reproducible builds for Tor, obfs4proxy, Snowflake, and vendored tunnel dependencies

No private signing keys belong in this repository.
