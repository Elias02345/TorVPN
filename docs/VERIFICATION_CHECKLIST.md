# Verification Checklist

This is the list of checks that must pass **on real machines/devices** before
TorTunnel may claim to provide anonymity (i.e. before Strict Mode is allowed to
report `protected`). The code for every adapter is written and compiles in CI,
but the privileged, system-wide leak protection has **not been verified on real
hardware yet**. Until every box here is ticked and the
[`STABLE_BLOCKERS`](audit/STABLE_BLOCKERS.md) are closed, builds are a
technology preview only.

Legend: ☐ = to do · 🤖 = already proven in CI · 👤 = needs a human + real device.

## 0. Build & supply chain

- [x] 🤖 `flutter analyze` and `flutter test` pass.
- [x] 🤖 `cargo fmt --check`, `cargo clippy -D warnings`, `cargo test --workspace` pass.
- [x] 🤖 `cargo deny check` passes (advisories, bans, licenses, sources).
- [x] 🤖 Android debug APK builds.
- [x] 🤖 Linux CLI + helper, Linux/Windows desktop bundles build and are released.
- [ ] 👤 Reproducible build of the bundled `tor` is documented and verified
      (see [`release/REPRODUCIBLE_BUILDS.md`](release/REPRODUCIBLE_BUILDS.md)).

## 1. Tor engine (all platforms)

- [x] 🤖 `tortunnel up` launches real tor and reaches a bootstrapped SOCKS proxy
      (CI `tor-integration` job, bootstraps to 100%).
- [ ] 👤 `curl --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/api/ip`
      reports `IsTor: true`.
- [ ] 👤 `SIGNAL NEWNYM` rotates the exit (observed change in exit IP).
- [ ] 👤 Exit-country preference is honoured when relays are available, and falls
      back transparently (and visibly) when not.
- [ ] 👤 obfs4 / Snowflake pluggable transports bootstrap on a censored network.

## 2. Linux system tunnel (helper: TUN + nftables + tun2proxy)

- [ ] 👤 `tortunnel-helper up` brings the tunnel up as root and routes all TCP
      through Tor (verified from a browser and `curl`).
- [ ] 👤 `check.torproject.org` reports `IsTor: true` for ordinary apps (not just
      SOCKS-aware ones).
- [ ] 👤 **DNS leak test** (e.g. dnsleaktest.com) shows only Tor exit resolvers.
- [ ] 👤 **IPv6 is blocked**: `curl -6 https://ifconfig.co` fails / no IPv6 egress.
- [ ] 👤 **UDP is blocked**: a UDP probe (e.g. `nc -u`) cannot leave directly.
- [ ] 👤 **Kill-switch holds**: stop tun2proxy / kill tor → no traffic leaks
      (nftables default-drop verified with `nft list ruleset`).
- [ ] 👤 Kill-switch holds across suspend/resume and network changes (Wi-Fi↔LAN).
- [ ] 👤 `tortunnel-helper down` removes the nftables table and TUN device cleanly.
- [ ] 👤 tor's uid matches the `--tor-uid` allowed by the kill-switch on the target
      distro (Debian/Ubuntu `debian-tor`, Fedora `toranon`, Arch `tor`).
- [ ] 👤 Works on Ubuntu/Debian, Arch, and Fedora (the three desktop targets).

## 3. Android (`VpnService`)

- [ ] 👤 The VPN establishes, the key icon appears, and traffic routes through Tor.
- [ ] 👤 `IsTor: true` from the device browser.
- [ ] 👤 DNS queries resolve through Tor only (no system DNS leak).
- [ ] 👤 IPv6 and UDP do not leak (IPv4-only TUN, no split routes).
- [ ] 👤 **Always-on + Lockdown**: with "Block connections without VPN" enabled,
      nothing leaks before/after the tunnel or if the service dies.
- [ ] 👤 Tunnel survives Doze, app kill, and device rotation; reconnects cleanly.
- [ ] 👤 The bundled tor + tun2proxy native libraries are built for all ABIs
      (arm64-v8a, armeabi-v7a, x86_64) and load at runtime.

## 4. Windows (`tortunnel-winsvc`: Wintun + WFP)

- [ ] 👤 The service installs, opens a Wintun adapter, and routes traffic via Tor.
- [ ] 👤 `IsTor: true` from a browser.
- [ ] 👤 WFP kill-switch blocks all outbound except tor (verified by stopping the
      service mid-session — no leak).
- [ ] 👤 DNS, IPv6, and UDP do not leak.
- [ ] 👤 Holds across sleep/resume, fast-user-switch, and adapter changes.
- [ ] 👤 Clean uninstall removes WFP filters and the Wintun adapter.

## 5. UI / product

- [ ] 👤 Strict Mode shows `protected` **only** after the adapter reports
      production-ready and the leak tests above pass (fail-closed gate).
- [ ] 👤 Compatibility Mode is always visibly marked as reduced protection and can
      never display the same status as Strict Mode.
- [ ] 👤 The world map's live refresh fetches Onionoo **through Tor** once
      connected (no clearnet request) and falls back to the snapshot otherwise.
- [ ] 👤 Diagnostics export is local, manual, and redacted (no IPs/keys).

## 6. Release hardening (human-gated / paid)

- [ ] 👤 Android APK is signed with a release keystore.
- [ ] 👤 Windows artifacts are Authenticode-signed.
- [ ] 👤 Linux artifacts ship detached signatures; Flatpak/AppImage are signed.
- [ ] 👤 External security/privacy audit completed; all High/Medium findings fixed
      and re-verified.
- [ ] 👤 Wintun redistribution license reviewed
      ([`legal/WINTUN_REVIEW.md`](legal/WINTUN_REVIEW.md)).

---

When sections 1–5 pass on every supported platform and section 6 is complete,
flip the production-ready gates documented in
[`../CLAUDE.md`](../CLAUDE.md#sacred-paths--never-break-or-weaken) — and not before.
