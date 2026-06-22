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
    final verification = core.lastVerification;
    return PageFrame(
      title: strings.activity,
      subtitle: strings.isGerman
          ? 'Verbindungsdetails bleiben lokal und werden nur manuell exportiert.'
          : 'Connection details stay local and are exported only manually.',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 860 ? 3 : 1;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: columns == 3 ? 2.2 : 3.6,
              children: [
                MetricTile(
                  icon: Icons.flag_rounded,
                  label: strings.isGerman
                      ? 'Beobachtetes Exit-Land'
                      : 'Observed exit country',
                  value: core.status.exitCountry ?? 'none',
                  color: AppColors.cyan,
                ),
                MetricTile(
                  icon: Icons.lan_rounded,
                  label: strings.isGerman
                      ? 'Beobachtete Exit-IP'
                      : 'Observed exit IP',
                  value: core.status.exitIp ?? 'none',
                  color: AppColors.good,
                ),
                MetricTile(
                  icon: Icons.account_tree_rounded,
                  label: strings.isGerman
                      ? 'Circuit-Isolation'
                      : 'Circuit isolation',
                  value: strings.isGerman ? 'Pro App' : 'Per app',
                  color: AppColors.warn,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.verifyExit,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                verification == null
                    ? (strings.isGerman
                          ? 'Noch keine Exit-Prüfung in dieser Sitzung.'
                          : 'No exit verification in this session yet.')
                    : verification.message,
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
                    onPressed: core.status.isActive
                        ? core.rotateIdentity
                        : null,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(strings.newIdentity),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.leakSelfTest,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                strings.isGerman
                    ? 'Selbsttests blockieren Stable, bis native Adapter echte Geräte-/VM-Tests bestehen.'
                    : 'Self-tests block stable until native adapters pass real device/VM checks.',
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: core.runLeakSelfTest,
                icon: const Icon(Icons.science_rounded),
                label: Text(strings.leakSelfTest),
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
                          Icons.block_rounded,
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
        ),
        const SizedBox(height: 14),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.exportDiagnostics,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              SelectableText(
                core.exportDiagnostics(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
