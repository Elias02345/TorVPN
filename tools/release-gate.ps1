Write-Host "TorTunnel release gate"
Write-Host "- CI must pass"
Write-Host "- docs/audit/STABLE_BLOCKERS.md must be empty or explicitly waived by audit process"
Write-Host "- Artifacts must be signed"
Write-Host "- Leak-test reports must be attached"
exit 1
