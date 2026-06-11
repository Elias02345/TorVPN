# Security Overhaul Scan

Date: 2026-06-11

Scope: repository-wide defensive scan of the local TorTunnel checkout.

Method: six independent review workers were requested. The environment allowed one worker first, then five more after closing prior planning agents. Five completed with convergent findings; one terminated during thread cleanup before returning unique results. Additional completed passes repeated the same root causes.

## Fixed Findings

1. Scaffold core reported fake protection evidence
   - Status: fixed.
   - Change: `TorTunnelCore.connect()` now fails closed while platform adapters are not production-ready. It returns a blocked status with no exit IP/country and without observed kill-switch, DNS, UDP, or IPv6 protection claims.
   - Change: Flutter mock/FFI locked states now render planned protections as gated, not verified.
   - Change: `verify_exit()` no longer treats degraded scaffold state as verifiable Tor exit state.

2. Torrc directive injection through unvalidated strings
   - Status: fixed for current string sinks.
   - Change: connection requests validate exit countries as two-letter alphabetic codes.
   - Change: bridge/custom transport values reject CR, LF, NUL, and unsafe tokens before torrc generation.
   - Coverage: tests reject multiline country and bridge injection payloads.

3. Raw torrc preview in diagnostics
   - Status: fixed by default omission.
   - Change: diagnostic export now omits `tor_config_preview` by default.
   - Remaining optional future work: implement explicit sensitive-debug export with structural redaction if needed.

4. Bare-name FFI library loading
   - Status: partially fixed.
   - Change: Dart now attempts application-bundle/executable-relative absolute paths and no longer opens a bare library name from OS search paths.
   - Change: FFI JSON envelopes must include `protocol_version: 1` and boolean `ok`.
   - Remaining work: add platform-specific signature/hash verification once release packaging owns native library provenance.

5. FFI parser optimistic safety defaults
   - Status: fixed.
   - Change: missing `udp_blocked` or `ipv6_blocked` fields now parse as false, not true.
   - Remaining work: add a dedicated unit-testable parser wrapper if FFI parsing grows.

6. Android release signed with debug key
   - Status: fixed.
   - Change: release build type no longer assigns the debug signing config.
   - Remaining work: production signing must be provided by CI/offline release process before stable artifacts exist.

7. Debian polkit cached admin authorization
   - Status: fixed.
   - Change: helper policy now uses `auth_admin` rather than `auth_admin_keep` for active sessions.

## Deferred Findings

1. Android IPv6 capture/drop path
   - Status: deferred, not hidden.
   - Reason: the Android adapter is still a scaffold; production packet loop and device leak tests are outside this code-only pass.
   - Gate: Strict Mode remains blocked until Android IPv6 behavior is implemented and leak-tested.

2. FFI pointer+length ABI hardening
   - Status: deferred.
   - Reason: changing every JSON C ABI entrypoint from NUL-terminated strings to pointer+length is an ABI migration that needs coordinated Dart/Rust changes and compatibility policy.
   - Current mitigation: Dart owns the only in-repo caller and passes valid NUL-terminated UTF-8; envelope/version validation was added.

3. CI action SHA pinning and Gradle distribution hash
   - Status: deferred.
   - Reason: pinning third-party action commit SHAs and Gradle distribution hashes requires source-of-truth update policy.
   - Recommendation: perform before public release.

## Residual Stable Blockers

- Native platform adapters remain non-production.
- Real-device/VM leak matrix has not passed.
- Wintun/legal/signing review remains open.
- External audit remains open.
- Stable release gate remains intentionally closed.
