import 'package:flutter/material.dart';

import '../core/core_models.dart';
import '../core/mock_core_client.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'shared.dart';

class AppExceptionsPage extends StatelessWidget {
  const AppExceptionsPage({
    required this.core,
    required this.strings,
    super.key,
  });

  final MockCoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: strings.appExceptions,
      subtitle: strings.isGerman
          ? 'Ausnahmen sind manuell, sichtbar und reduzieren den Schutz der betroffenen Apps.'
          : 'Exceptions are manual, visible, and reduce protection for affected apps.',
      children: [
        InfoCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                core.connectionMode == ConnectionMode.strict
                    ? Icons.shield_rounded
                    : Icons.warning_rounded,
                color: core.connectionMode == ConnectionMode.strict
                    ? AppColors.good
                    : AppColors.warn,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  core.connectionMode == ConnectionMode.strict
                      ? (strings.isGerman
                            ? 'Strict Mode ist aktiv. App-Ausnahmen sind deaktiviert, damit kein direkter Fallback entsteht.'
                            : 'Strict Mode is active. App exceptions are disabled to prevent direct fallback.')
                      : (strings.isGerman
                            ? 'Compatibility Mode erlaubt App-Ausnahmen, ist aber reduzierter Schutz.'
                            : 'Compatibility Mode allows app exceptions, but this is reduced protection.'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final exception in core.appExceptions) ...[
          InfoCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.apps_rounded, color: AppColors.cyan),
              title: Text(exception.displayName),
              subtitle: Text(exception.reason),
              value: exception.enabled,
              onChanged: core.connectionMode == ConnectionMode.strict
                  ? null
                  : (value) => core.toggleAppException(exception.appId, value),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
