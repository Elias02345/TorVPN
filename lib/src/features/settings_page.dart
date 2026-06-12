import 'package:flutter/material.dart';

import '../core/core_client.dart';
import '../core/core_models.dart';
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
          ? 'Nur die wichtigsten Optionen.'
          : 'Only the essentials.',
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.mode,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              SegmentedButton<ConnectionMode>(
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
              const SizedBox(height: 12),
              Text(
                core.connectionMode == ConnectionMode.strict
                    ? (strings.isGerman
                          ? 'Strict Mode: keine App-Ausnahmen.'
                          : 'Strict Mode: no app exceptions.')
                    : (strings.isGerman
                          ? 'Kompatibilitaet: reduziert Schutz fuer problematische Apps.'
                          : 'Compatibility: reduces protection for problematic apps.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.languageLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
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
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.bridges,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<BridgeKind>(
                isExpanded: true,
                initialValue: core.bridgeConfig.kind,
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
                  core.setBridgeConfig(_bridgeConfig(kind));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.article_rounded, color: AppColors.cyan),
            title: Text(
              strings.isGerman ? 'Lokale Diagnose' : 'Local diagnostics',
            ),
            subtitle: Text(
              strings.isGerman
                  ? 'Bleibt auf dem Geraet und wird nur manuell kopiert.'
                  : 'Stays on device and is copied only manually.',
            ),
            value: core.localVerboseDiagnostics,
            onChanged: core.setVerboseDiagnostics,
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          color: AppColors.surfaceWarm,
          borderColor: AppColors.warn.withValues(alpha: 0.36),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 10),
            leading: const Icon(Icons.info_rounded, color: AppColors.warn),
            title: Text(
              strings.isGerman ? 'Alpha-Status' : 'Alpha status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              strings.isGerman
                  ? 'Stable-Release bleibt gesperrt.'
                  : 'Stable release remains locked.',
            ),
            children: [ReadinessSteps(steps: core.releaseReadiness.steps)],
          ),
        ),
      ],
    );
  }

  BridgeConfig _bridgeConfig(BridgeKind kind) {
    return switch (kind) {
      BridgeKind.none => const BridgeConfig(
        kind: BridgeKind.none,
        label: 'No bridges',
      ),
      BridgeKind.manualObfs4 => const BridgeConfig(
        kind: BridgeKind.manualObfs4,
        label: 'Manual obfs4',
        lines: ['obfs4 <bridge>:<port> cert=<fingerprint> iat-mode=0'],
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
  }
}
