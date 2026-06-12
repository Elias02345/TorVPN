import 'package:flutter/material.dart';

import '../core/core_client.dart';
import '../core/core_models.dart';
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
          ? 'Waehle eine einfache Exit-Praeferenz.'
          : 'Choose a simple exit preference.',
      children: [
        for (final profile in core.profiles) ...[
          _ProfileChoice(
            profile: profile,
            selected: profile.id == core.selectedProfile.id,
            onTap: () => core.setSelectedProfile(profile),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
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
                      ? 'Tor behandelt Laender als Wunsch. Wenn Relays fehlen oder instabil sind, kann ein anderes Exit-Land genutzt werden.'
                      : 'Tor treats countries as a preference. If relays are missing or unstable, another exit country can be used.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _RelaySummary(core: core, strings: strings),
      ],
    );
  }
}

class _ProfileChoice extends StatelessWidget {
  const _ProfileChoice({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final CountryProfile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      color: selected ? AppColors.cyan.withValues(alpha: 0.10) : null,
      borderColor: selected ? AppColors.cyan : AppColors.border,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? AppColors.cyan : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(profile.description),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final country in profile.exitCountries)
                        StatusPill(
                          icon: Icons.flag_rounded,
                          label: country,
                          color: AppColors.cyan,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelaySummary extends StatelessWidget {
  const _RelaySummary({required this.core, required this.strings});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.hub_rounded,
            title: strings.isGerman ? 'Relay-Uebersicht' : 'Relay summary',
            subtitle: strings.isGerman
                ? 'Nur zur Orientierung, nicht als Garantie.'
                : 'For orientation only, not a guarantee.',
          ),
          const SizedBox(height: 12),
          for (final country in core.relayCountries) ...[
            Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    country.countryCode,
                    style: const TextStyle(
                      color: AppColors.textHigh,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(child: Text(country.countryName)),
                Text(
                  '${country.exitRelays}',
                  style: const TextStyle(
                    color: AppColors.textHigh,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (country != core.relayCountries.last)
              const Divider(color: AppColors.border),
          ],
        ],
      ),
    );
  }
}
