# Leak Test Matrix

Run these tests before any public stable release.

| Area | Android | Linux | Windows | Acceptance |
| --- | --- | --- | --- | --- |
| Exit IP | VpnService | TUN route | Wintun route | Public IP is Tor exit after connect |
| DNS | VPN DNS | nftables/DNSPort | WFP/DNS policy | No system resolver bypass |
| IPv6 | Blocked | Blocked | Blocked | IPv6 test shows no direct route |
| UDP | Blocked | Blocked | Blocked | UDP cannot bypass TorTunnel |
| Kill-switch | Always-on VPN | nftables default-deny | WFP default-deny | Traffic blocked during Tor failure |
| Network change | Wi-Fi/mobile | interface change | interface change | No direct traffic during reconnect |
| Sleep/resume | resume event | resume event | resume event | Kill-switch remains active |
| App exceptions | per-app VPN APIs | TBD | TBD | Exceptions are visible and deliberate |
| Exit fallback | Tor ControlPort | Tor ControlPort | Tor ControlPort | Fallback is shown to user |
| Diagnostics | local export | local export | local export | No identifiers or automatic upload |

Stable release requires the matrix to be run against:

- Android emulator and at least two physical Android 10+ devices.
- Linux GNOME/Wayland, X11, and one non-Ubuntu distro VM.
- Windows 10 and Windows 11 VMs with fresh install, upgrade, and uninstall passes.
