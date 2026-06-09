# Reproducible Builds

Stable releases require pinned and reproducible build inputs:

- Flutter SDK version
- Rust toolchain version and installed components
- Android SDK/NDK versions
- Tor source release and signature
- obfs4proxy source release and signature
- Snowflake source release and signature
- vendored `tun2proxy` source revision and license metadata

Release CI must publish:

- SBOM
- checksums
- signing provenance
- build logs
- leak-test reports
