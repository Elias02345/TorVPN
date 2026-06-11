import 'package:flutter/material.dart';

import '../core/core_client.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'shared.dart';

class CountriesPage extends StatelessWidget {
  const CountriesPage({required this.core, required this.strings, super.key});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: strings.countries,
      subtitle: strings.isGerman
          ? 'Exit-Laender sind Praeferenzen, keine Standort-Garantien.'
          : 'Exit countries are preferences, not location guarantees.',
      children: [
        Panel(
          color: AppColors.surfaceWarm,
          borderColor: AppColors.warn.withValues(alpha: 0.36),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_rounded, color: AppColors.warn),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.isGerman
                      ? 'Tor kann Exit-Wuensche ignorieren, wenn Stabilitaet oder Verfuegbarkeit es erfordern. Die App zeigt Fallbacks sichtbar an.'
                      : 'Tor can ignore exit preferences when stability or availability requires it. The app keeps fallback visible.',
                ),
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
                strings.preferredExitCountries,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final profile in core.profiles)
                    ChoiceChip(
                      label: Text(
                        '${profile.name} (${profile.exitCountries.join(', ')})',
                      ),
                      selected: core.selectedProfile.id == profile.id,
                      onSelected: (_) => core.setSelectedProfile(profile),
                      selectedColor: AppColors.cyan.withValues(alpha: 0.18),
                      side: const BorderSide(color: AppColors.border),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 2 : 1;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: columns == 2 ? 3.8 : 2.8,
              children: [
                for (final country in core.relayCountries)
                  _CountryRelayCard(
                    countryName: country.countryName,
                    code: country.countryCode,
                    exits: country.exitRelays,
                    available: country.available,
                    stability: country.stabilityScore,
                    strings: strings,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CountryRelayCard extends StatelessWidget {
  const _CountryRelayCard({
    required this.countryName,
    required this.code,
    required this.exits,
    required this.available,
    required this.stability,
    required this.strings,
  });

  final String countryName;
  final String code;
  final int exits;
  final bool available;
  final int stability;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.good : AppColors.warn;
    return InfoCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.textHigh,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  countryName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  strings.isGerman
                      ? '$exits Exit-Relays · Stabilität $stability%'
                      : '$exits exit relays · Stability $stability%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StatusPill(
            icon: available ? Icons.check_rounded : Icons.pause_rounded,
            label: available
                ? (strings.isGerman ? 'Verfügbar' : 'Available')
                : (strings.isGerman ? 'Keine Exits' : 'No exits'),
            color: color,
          ),
        ],
      ),
    );
  }
}
