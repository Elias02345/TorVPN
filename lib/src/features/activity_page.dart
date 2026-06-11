import 'package:flutter/material.dart';

import '../core/core_client.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'shared.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({required this.core, required this.strings, super.key});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: strings.isGerman ? 'Evidence' : 'Evidence',
      subtitle: strings.isGerman
          ? 'Pruefbare lokale Belege statt Schutzversprechen.'
          : 'Local evidence instead of protection promises.',
      trailing: OutlinedButton.icon(
        onPressed: core.runLeakSelfTest,
        icon: const Icon(Icons.science_rounded),
        label: Text(strings.leakSelfTest),
      ),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final leakMatrix = _LeakMatrixPanel(core: core, strings: strings);
            final quickChecks = _QuickChecksPanel(core: core, strings: strings);
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [leakMatrix, const SizedBox(height: 14), quickChecks],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: leakMatrix),
                const SizedBox(width: 14),
                Expanded(flex: 4, child: quickChecks),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _ClaimsPanel(core: core, strings: strings),
        const SizedBox(height: 14),
        _DiagnosticsPanel(core: core, strings: strings),
      ],
    );
  }
}

class _LeakMatrixPanel extends StatelessWidget {
  const _LeakMatrixPanel({required this.core, required this.strings});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.fact_check_rounded,
            title: strings.isGerman ? 'Leak-Matrix' : 'Leak matrix',
            subtitle: strings.isGerman
                ? 'Alles bleibt blockiert oder pending, bis Zielgeraete bestanden sind.'
                : 'Everything remains blocked or pending until target devices pass.',
          ),
          const SizedBox(height: 14),
          EvidenceTable(items: core.releaseReadiness.evidence),
        ],
      ),
    );
  }
}

class _QuickChecksPanel extends StatelessWidget {
  const _QuickChecksPanel({required this.core, required this.strings});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.bolt_rounded,
            title: strings.isGerman ? 'Schnellpruefungen' : 'Quick checks',
            subtitle: strings.isGerman
                ? 'Diese Aktionen bleiben lokal und manuell.'
                : 'These actions stay local and manual.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: core.verifyExit,
                icon: const Icon(Icons.travel_explore_rounded),
                label: Text(strings.verifyExit),
              ),
              OutlinedButton.icon(
                onPressed: core.status.isActive ? core.rotateIdentity : null,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(strings.newIdentity),
              ),
              OutlinedButton.icon(
                onPressed: core.runLeakSelfTest,
                icon: const Icon(Icons.science_rounded),
                label: Text(strings.leakSelfTest),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            core.lastVerification == null
                ? (strings.isGerman
                      ? 'Noch keine Exit-Pruefung in dieser Sitzung.'
                      : 'No exit verification in this session yet.')
                : core.lastVerification!.message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (core.lastLeakSelfTest != null) ...[
            const SizedBox(height: 14),
            for (final result in core.lastLeakSelfTest!.results)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      color: AppColors.warn,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${result.kind}: ${result.status} - ${result.message}',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ClaimsPanel extends StatelessWidget {
  const _ClaimsPanel({required this.core, required this.strings});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.policy_rounded,
            title: strings.isGerman ? 'Claim-Gates' : 'Claim gates',
            subtitle: strings.isGerman
                ? 'Jede sichtbare Schutz-Aussage braucht eine Evidence-ID.'
                : 'Every visible protection claim needs an evidence ID.',
          ),
          const SizedBox(height: 14),
          ClaimList(claims: core.protectionClaims),
        ],
      ),
    );
  }
}

class _DiagnosticsPanel extends StatelessWidget {
  const _DiagnosticsPanel({required this.core, required this.strings});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.file_download_rounded,
            title: strings.exportDiagnostics,
            subtitle: strings.isGerman
                ? 'Kein Upload, kein Konto, keine Telemetrie.'
                : 'No upload, no account, no telemetry.',
          ),
          const SizedBox(height: 12),
          SelectableText(
            core.exportDiagnostics(),
            style: const TextStyle(
              fontFamily: 'monospace',
              color: AppColors.textMuted,
              height: 1.45,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
