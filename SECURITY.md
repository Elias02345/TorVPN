# Security Policy

## Supported Versions

TorTunnel is pre-alpha. No build is supported for production anonymity or production VPN use until the native tunnel adapters pass leak testing and an external audit.

## Reporting Vulnerabilities

Please report security issues privately through the repository security advisory flow when available. Do not include live credentials, private browsing data, or unredacted logs.

## Privacy Rules

- No telemetry.
- No account system.
- No automatic crash upload.
- No server-side relay health collection.
- Diagnostic bundles must be local, manually exported, and redacted.

## Pre-v1 Security Gates

- DNS leak tests pass on Android, Linux, and Windows.
- IPv6 is blocked or safely routed on every supported platform.
- UDP is blocked except for explicitly designed DNS handling.
- Kill-switch remains active during Tor startup, crash, reconnect, sleep/resume, and network changes.
- Release artifacts are signed.
- External security/privacy audit is complete.
- All High and Medium audit findings are fixed and re-verified.
- Strict Mode has no app exceptions and no direct network fallback.
