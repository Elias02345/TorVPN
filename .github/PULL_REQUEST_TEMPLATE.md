<!-- Thanks for contributing to TorTunnel. Keep changes small and testable. -->

## Summary

<!-- What does this change do, and why? -->

## Privacy & safety checklist

- [ ] Does not weaken the kill-switch, DNS-over-Tor, UDP-block, or IPv6-block policy
      (or updates `docs/THREAT_MODEL.md` and `docs/LEAK_TEST_MATRIX.md` if it does).
- [ ] Keeps app exceptions out of Strict Mode; Compatibility Mode stays clearly
      marked as reduced protection.
- [ ] No telemetry, accounts, automatic upload, or hidden direct-network fallback.
- [ ] No secrets, keys, or machine-specific paths committed.

## Verification

- [ ] `flutter analyze` and `flutter test` pass.
- [ ] `cargo fmt --check`, `cargo clippy --workspace --all-targets -- -D warnings`,
      `cargo test --workspace`, and `cargo deny check` pass.
- [ ] Docs updated for any public behavior change.

## Platform impact

<!-- Note any Android / Linux / Windows specific behavior or testing. -->
