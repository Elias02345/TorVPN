# Windows Packaging

This directory contains the Windows installer/service contract. It is not stable-ready until signing, Wintun review, and WFP leak tests pass.

Before Windows release:

- Bundle the Flutter Windows app.
- Package the Rust core DLL.
- Install a signed service for Wintun and WFP policy.
- Keep WFP block rules active during Tor failures.
- Sign the installer and binaries.
