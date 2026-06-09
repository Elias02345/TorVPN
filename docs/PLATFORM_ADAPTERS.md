# Platform Adapter Implementation Contracts

## Android

- Use `VpnService.prepare()` before starting `TorTunnelVpnService`.
- Do not call `allowBypass()` in Strict Mode.
- Do not enable IPv6 address family in Strict Mode.
- Protect Tor outbound sockets with `VpnService.protect()`.
- Disable app exceptions when `isLockdownEnabled` is true.

## Linux

- UI must stay unprivileged.
- systemd/polkit helper owns TUN, route changes, and `inet tortunnel` nftables rules.
- Default-deny rules must be active before Tor bootstrap.
- Only Tor/helper marked traffic may reach the physical network.

## Windows

- Signed service owns Wintun and WFP rules.
- WFP blocks direct outbound traffic except the Tor service.
- Wintun integration is blocked on legal/signing review.
- MSI install/uninstall must clean service, adapter, and WFP state.
