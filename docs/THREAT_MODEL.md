# Threat Model

## Goals

- Prevent accidental direct IP, DNS, UDP, and IPv6 leaks while TorTunnel is connected.
- Make exit-country selection a preference with transparent fallback, not a false guarantee.
- Avoid backend, account, telemetry, and automatic upload dependencies.
- Keep diagnostics local and manually exported.

## Non-Goals

- TorTunnel is not a high-speed commercial VPN.
- TorTunnel does not guarantee streaming, gaming, or P2P compatibility.
- TorTunnel does not hide that Tor is being used from every network observer.
- TorTunnel does not run relays, bridges, or exits in the MVP.

## Primary Risks

- DNS requests bypassing Tor.
- IPv6 routes bypassing Tor.
- UDP traffic bypassing Tor or silently failing in confusing ways.
- Kill-switch gaps during sleep/resume, network changes, Tor crashes, or app crashes.
- Desktop app exceptions becoming implicit traffic bypasses.
- Users believing exit-country preference is strict location control.
- Compatibility Mode being confused with Strict Mode.

## Required Mitigations

- Kill-switch must be enabled before connection bootstrap and remain active during errors.
- UDP and IPv6 are blocked in MVP.
- DNS must resolve through Tor-compatible handling.
- Exit country fallback must be visible in status details.
- App exceptions must be opt-in and visible.
- Strict Mode must disable app exceptions completely.
- Tor limits and P2P warning must appear in onboarding.
