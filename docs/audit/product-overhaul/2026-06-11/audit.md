# TorTunnel Product Overhaul Audit

Date: 2026-06-11

Surface: Flutter app shell, Home, Countries, Exceptions, Evidence, and Settings.

Destination: local folder, `docs/audit/product-overhaul/2026-06-11/`.

## Capture Status

The app is a native Flutter desktop/mobile target, not a browser surface. Browser capture is not applicable. A Flutter widget screenshot capture attempt was rejected because the local `flutter_tester` process hung before producing PNG files. The audit therefore uses current-code inspection plus passing responsive widget tests as evidence, with screenshot capture recorded as a blocker to resolve in a follow-up visual QA pass.

## Steps Audited

1. Home readiness
   - Health: good functional direction.
   - The screen now leads with "Setup not ready for real protection" / "Setup nicht bereit fuer echten Schutz" and disables the real connect action.
   - The primary user action is setup review, not a misleading connection promise.

2. Release steps
   - Health: good.
   - Native adapter, leak tests, and release audit are visible as separate gates with evidence IDs.
   - No step is presented as verified while repo blockers remain.

3. Country preference
   - Health: good.
   - Copy now says exit countries are preferences, not guarantees.
   - The profile selector is expanded for mobile to avoid clipped labels.

4. App exceptions
   - Health: acceptable.
   - Strict Mode keeps exceptions disabled and prevents direct fallback.
   - A later audit should check the Compatibility Mode flow with real installed app metadata.

5. Evidence and diagnostics
   - Health: good.
   - Leak matrix rows are represented by local evidence records with status and evidence IDs.
   - Diagnostic export remains manual and local-only.

6. Settings and release status
   - Health: good.
   - Settings now shows a stable-release lock before mode, bridge, language, and diagnostics controls.
   - The mode segmented control was moved out of `ListTile.trailing` to avoid mobile overflow.

## Accessibility Risks

- Screenshot-only contrast verification is still missing because native capture failed.
- Keyboard focus order and screen-reader labels need manual device QA after a runnable desktop/mobile build is available.
- The app uses icon-led status rows; future QA should verify every icon has adjacent text or tooltip-equivalent context.

## Follow-Up

- Add a stable visual capture harness for Flutter that does not hang on this Windows runner.
- Re-run visual audit with desktop and mobile screenshots before any public release.
- Keep all protection copy backed by `ProtectionClaim` or `LeakEvidenceItem` evidence IDs.
