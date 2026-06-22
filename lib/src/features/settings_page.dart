import 'package:flutter/material.dart';

import '../core/core_models.dart';
import '../core/core_client.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'shared.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.core,
    required this.strings,
    required this.language,
    required this.onLanguageChanged,
    super.key,
  });

  final CoreClient core;
  final AppStrings strings;
  final LanguageChoice language;
  final ValueChanged<LanguageChoice> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: strings.settings,
      subtitle: strings.isGerman
          ? 'Privacy-Defaults, Sprache und lokale Diagnose.'
          : 'Privacy defaults, language, and local diagnostics.',
      children: [
        InfoCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.policy_rounded,
                  color: AppColors.cyan,
                ),
                title: Text(strings.mode),
                subtitle: Text(
                  core.connectionMode == ConnectionMode.strict
                      ? (strings.isGerman
                            ? 'Keine App-Ausnahmen, kein direkter Fallback, UDP/IPv6 blockiert.'
                            : 'No app exceptions, no direct fallback, UDP/IPv6 blocked.')
                      : (strings.isGerman
                            ? 'App-Ausnahmen erlaubt, aber nur mit reduziertem Schutz.'
                            : 'App exceptions allowed, but only with reduced protection.'),
                ),
                trailing: SegmentedButton<ConnectionMode>(
                  segments: [
                    ButtonSegment(
                      value: ConnectionMode.strict,
                      icon: const Icon(Icons.shield_rounded),
                      label: Text(strings.strictMode),
                    ),
                    ButtonSegment(
                      value: ConnectionMode.compatibilityReducedProtection,
                      icon: const Icon(Icons.warning_rounded),
                      label: Text(strings.compatibilityMode),
                    ),
                  ],
                  selected: {core.connectionMode},
                  onSelectionChanged: (selection) =>
                      core.setConnectionMode(selection.first),
                ),
              ),
              const Divider(color: AppColors.border),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(
                  Icons.power_rounded,
                  color: AppColors.cyan,
                ),
                title: Text(strings.autoConnect),
                subtitle: Text(
                  strings.isGerman
                      ? 'Beim Systemstart automatisch mit dem letzten Profil verbinden.'
                      : 'Connect at system startup with the last profile.',
                ),
                value: core.autoConnect,
                onChanged: core.setAutoConnect,
              ),
              const Divider(color: AppColors.border),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.cyan,
                ),
                title: Text(strings.autoRotation),
                subtitle: Text(
                  strings.isGerman
                      ? 'Neue Tor-Identität nach Zeitplan; bleibt hinter Core-Unterstützung.'
                      : 'Scheduled new Tor identity; gated on core support.',
                ),
                value: core.autoRotation,
                onChanged: core.setAutoRotation,
              ),
              const Divider(color: AppColors.border),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(
                  Icons.article_rounded,
                  color: AppColors.cyan,
                ),
                title: Text(
                  strings.isGerman
                      ? 'Ausführliche lokale Diagnose'
                      : 'Verbose local diagnostics',
                ),
                subtitle: Text(
                  strings.isGerman
                      ? 'Bleibt lokal und wird nur manuell exportiert.'
                      : 'Stays local and is exported only manually.',
                ),
                value: core.localVerboseDiagnostics,
                onChanged: core.setVerboseDiagnostics,
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
                strings.bridges,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<BridgeKind>(
                initialValue: core.bridgeConfig.kind,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: BridgeKind.none, child: Text('None')),
                  DropdownMenuItem(
                    value: BridgeKind.manualObfs4,
                    child: Text('Manual obfs4'),
                  ),
                  DropdownMenuItem(
                    value: BridgeKind.snowflake,
                    child: Text('Snowflake'),
                  ),
                ],
                onChanged: (kind) {
                  if (kind == null) {
                    return;
                  }
                  final config = switch (kind) {
                    BridgeKind.none => const BridgeConfig(
                      kind: BridgeKind.none,
                      label: 'No bridges',
                    ),
                    BridgeKind.manualObfs4 => const BridgeConfig(
                      kind: BridgeKind.manualObfs4,
                      label: 'Manual obfs4',
                      lines: [
                        'obfs4 <bridge>:<port> cert=<fingerprint> iat-mode=0',
                      ],
                    ),
                    BridgeKind.snowflake => const BridgeConfig(
                      kind: BridgeKind.snowflake,
                      label: 'Snowflake',
                    ),
                    BridgeKind.customTransport => const BridgeConfig(
                      kind: BridgeKind.customTransport,
                      label: 'Custom',
                    ),
                  };
                  core.setBridgeConfig(config);
                },
              ),
              const SizedBox(height: 10),
              Text(
                strings.isGerman
                    ? 'Bridge-Konfiguration ist lokal und benoetigt vor Stable echte obfs4/Snowflake-Bundles.'
                    : 'Bridge configuration is local and needs real obfs4/Snowflake bundles before stable.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        InfoCard(
          child: Row(
            children: [
              const Icon(Icons.translate_rounded, color: AppColors.cyan),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.languageLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SegmentedButton<LanguageChoice>(
                segments: const [
                  ButtonSegment(value: LanguageChoice.de, label: Text('DE')),
                  ButtonSegment(value: LanguageChoice.en, label: Text('EN')),
                ],
                selected: {language},
                onSelectionChanged: (selection) =>
                    onLanguageChanged(selection.first),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 3 : 1;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: columns == 3 ? 2.1 : 3.5,
              children: [
                MetricTile(
                  icon: Icons.visibility_off_rounded,
                  label: strings.noTelemetry,
                  value: strings.isGerman ? 'Erzwungen' : 'Enforced',
                  color: AppColors.good,
                ),
                MetricTile(
                  icon: Icons.verified_rounded,
                  label: strings.signedReleases,
                  value: strings.isGerman ? 'Geplant' : 'Planned',
                  color: AppColors.cyan,
                ),
                MetricTile(
                  icon: Icons.bug_report_rounded,
                  label: strings.manualCrashReports,
                  value: strings.isGerman ? 'Manuell' : 'Manual',
                  color: AppColors.warn,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        InfoCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.volunteer_activism_rounded,
                color: AppColors.good,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.isGerman
                      ? 'Finanzierung: Spendenlinks sind erlaubt, aber ohne Accounts, Werbung oder Tracking.'
                      : 'Funding: donation links are allowed, without accounts, ads, or tracking.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
