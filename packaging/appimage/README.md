# AppImage Packaging

This directory tracks the Linux AppImage release path. It is not stable-ready until the host helper install and nftables leak tests pass.

Before AppImage release:

- Bundle the Flutter Linux app.
- Package the Rust core dynamic library.
- Install or verify the privileged Linux helper.
- Document nftables and DNS policy requirements.
- Sign the artifact.
