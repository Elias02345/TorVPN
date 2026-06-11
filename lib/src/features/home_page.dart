import 'package:flutter/material.dart';

import '../core/core_client.dart';
import '../core/core_models.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'shared.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.core, required this.strings, super.key});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'TorTunnel',
      subtitle: strings.isGerman
          ? 'Ein Tor-Tunnel mit ehrlichen Schutz-Gates, bevor echte Adapter freigegeben werden.'
          : 'A Tor tunnel with honest protection gates before real adapters are released.',
      trailing: StatusPill(
        icon: Icons.laptop_mac_rounded,
        label: strings.localOnly,
        color: AppColors.good,
      ),
      children: [
        if (!core.onboardingDismissed) ...[
          _OnboardingNotice(core: core, strings: strings),
          const SizedBox(height: 14),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            final hero = _ReadinessHero(core: core, strings: strings);
            final steps = _SetupStepsPanel(core: core, strings: strings);
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [hero, const SizedBox(height: 14), steps],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: hero),
                const SizedBox(width: 14),
                Expanded(flex: 4, child: steps),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            final country = _ProfilePanel(core: core, strings: strings);
            final protection = _ProtectionSnapshot(
              core: core,
              strings: strings,
            );
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [country, const SizedBox(height: 14), protection],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: country),
                const SizedBox(width: 14),
                Expanded(child: protection),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _PlatformReadinessPanel(core: core, strings: strings),
        const SizedBox(height: 14),
        _AdvancedEvidencePanel(core: core, strings: strings),
        const SizedBox(height: 14),
        _PolicyNotice(strings: strings),
      ],
    );
  }
}

class _OnboardingNotice extends StatelessWidget {
  const _OnboardingNotice({required this.core, required this.strings});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Panel(
      color: AppColors.surfaceWarm,
      borderColor: AppColors.warn.withValues(alpha: 0.42),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_rounded, color: AppColors.warn),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.torLimitsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(strings.torLimitsBody),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: strings.isGerman ? 'Hinweis ausblenden' : 'Hide notice',
            child: IconButton(
              onPressed: core.dismissOnboarding,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessHero extends StatelessWidget {
  const _ReadinessHero({required this.core, required this.strings});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final canConnect = core.releaseReadiness.canAttemptRealConnection;
    return Panel(
      padding: const EdgeInsets.all(22),
      color: AppColors.backgroundHigh,
      borderColor: AppColors.warn.withValues(alpha: 0.44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                icon: Icons.lock_rounded,
                label: strings.isGerman
                    ? 'Setup nicht bereit'
                    : 'Setup not ready',
                color: AppColors.warn,
              ),
              StatusPill(
                icon: Icons.shield_rounded,
                label: strings.strictMode,
                color: AppColors.cyan,
              ),
              StatusPill(
                icon: Icons.cloud_off_rounded,
                label: strings.noBackend,
                color: AppColors.good,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            strings.isGerman
                ? 'Setup nicht bereit fuer echten Schutz'
                : 'Setup not ready for real protection',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            strings.isGerman
                ? 'TorTunnel sperrt den echten Verbindungsstart, bis native Adapter, Leak-Tests und Release-Audit belegbar bestanden sind.'
                : 'TorTunnel locks real connection start until native adapters, leak tests, and release audit evidence pass.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warn.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warn.withValues(alpha: 0.36)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.route_rounded, color: AppColors.warn),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    core.status.message == 'Disconnected'
                        ? (strings.isGerman
                              ? 'Connect gesperrt: Adapter sind noch nicht verifiziert.'
                              : 'Connect locked: adapters are not verified yet.')
                        : core.status.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const ValueKey('connect-button'),
                onPressed: canConnect ? core.connect : null,
                icon: const Icon(Icons.power_settings_new_rounded),
                label: Text(
                  canConnect
                      ? strings.connect
                      : (strings.isGerman
                            ? 'Connect gesperrt'
                            : 'Connect locked'),
                ),
              ),
              OutlinedButton.icon(
                key: const ValueKey('review-setup-button'),
                onPressed: core.runLeakSelfTest,
                icon: const Icon(Icons.fact_check_rounded),
                label: Text(
                  strings.isGerman ? 'Setup pruefen' : 'Review setup',
                ),
              ),
              OutlinedButton.icon(
                onPressed: core.exportDiagnostics,
                icon: const Icon(Icons.file_download_rounded),
                label: Text(strings.exportDiagnostics),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetupStepsPanel extends StatelessWidget {
  const _SetupStepsPanel({required this.core, required this.strings});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.checklist_rounded,
            title: strings.isGerman ? 'Freigabe-Schritte' : 'Release steps',
            subtitle: strings.isGerman
                ? 'Jeder Schritt braucht Belege, bevor Schutz behauptet wird.'
                : 'Each step needs evidence before protection is claimed.',
          ),
          const SizedBox(height: 14),
          ReadinessSteps(steps: core.releaseReadiness.steps),
        ],
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.core, required this.strings});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.public_rounded,
            title: strings.preferredExitCountries,
            subtitle: strings.isGerman
                ? 'Laender sind Praeferenzen, keine Standort-Garantien.'
                : 'Countries are preferences, not location guarantees.',
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: core.selectedProfile.id,
            items: [
              for (final profile in core.profiles)
                DropdownMenuItem(value: profile.id, child: Text(profile.name)),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              final profile = core.profiles.firstWhere(
                (item) => item.id == value,
              );
              core.setSelectedProfile(profile);
            },
          ),
          const SizedBox(height: 12),
          Text(core.selectedProfile.description),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final country in core.selectedProfile.exitCountries)
                StatusPill(
                  icon: Icons.flag_rounded,
                  label: country,
                  color: AppColors.cyan,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProtectionSnapshot extends StatelessWidget {
  const _ProtectionSnapshot({required this.core, required this.strings});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final status = core.status;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.shield_outlined,
            title: strings.isGerman ? 'Was ist geplant?' : 'What is planned?',
            subtitle: strings.isGerman
                ? 'Diese Werte bleiben gesperrt, bis echte Tests sie belegen.'
                : 'These values stay gated until real tests prove them.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ProtectionChip(
                icon: Icons.dns_rounded,
                title: strings.isGerman
                    ? 'TCP + DNS ueber Tor'
                    : 'TCP + DNS through Tor',
                value: status.dnsProtected ? 'Verified' : 'Gated',
                color: AppColors.cyan,
              ),
              _ProtectionChip(
                icon: Icons.block_rounded,
                title: strings.isGerman ? 'UDP blockiert' : 'UDP blocked',
                value: status.udpBlocked ? 'Verified' : 'Gated',
                color: status.udpBlocked ? AppColors.good : AppColors.warn,
              ),
              _ProtectionChip(
                icon: Icons.hub_rounded,
                title: strings.isGerman ? 'IPv6 blockiert' : 'IPv6 blocked',
                value: status.ipv6Blocked ? 'Verified' : 'Gated',
                color: status.ipv6Blocked ? AppColors.good : AppColors.warn,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProtectionChip extends StatelessWidget {
  const _ProtectionChip({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
      child: Panel(
        padding: const EdgeInsets.all(12),
        color: AppColors.surfaceHigh,
        borderColor: color.withValues(alpha: 0.35),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textHigh,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
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

class _PlatformReadinessPanel extends StatelessWidget {
  const _PlatformReadinessPanel({required this.core, required this.strings});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: Icons.devices_rounded,
            title: strings.isGerman
                ? 'Adapter-Bereitschaft'
                : 'Adapter readiness',
            subtitle: strings.isGerman
                ? 'Keine Plattform wird als bereit angezeigt, solange Belege fehlen.'
                : 'No platform is shown as ready while evidence is missing.',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 860;
              final tileWidth = wide
                  ? (constraints.maxWidth - 20) / 3
                  : constraints.maxWidth;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final platform
                      in core.releaseReadiness.platformReadiness)
                    SizedBox(
                      width: tileWidth,
                      child: _PlatformTile(platform: platform),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlatformTile extends StatelessWidget {
  const _PlatformTile({required this.platform});

  final PlatformReadiness platform;

  @override
  Widget build(BuildContext context) {
    final color = readinessColor(platform.status);
    return Panel(
      padding: const EdgeInsets.all(14),
      color: AppColors.surfaceHigh,
      borderColor: color.withValues(alpha: 0.35),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_platformIcon(platform.target), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform.adapterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  platform.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                StatusPill(
                  icon: readinessIcon(platform.status),
                  label: readinessLabel(platform.status),
                  color: color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _platformIcon(PlatformTarget target) {
    return switch (target) {
      PlatformTarget.android => Icons.android_rounded,
      PlatformTarget.linux => Icons.terminal_rounded,
      PlatformTarget.windows => Icons.window_rounded,
    };
  }
}

class _AdvancedEvidencePanel extends StatelessWidget {
  const _AdvancedEvidencePanel({required this.core, required this.strings});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 12),
        initiallyExpanded: false,
        title: Text(
          strings.isGerman ? 'Advanced Evidence' : 'Advanced evidence',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          strings.isGerman
              ? 'Leak-Matrix, Claim-Belege und lokale Diagnose.'
              : 'Leak matrix, claim evidence, and local diagnostics.',
        ),
        leading: const Icon(Icons.science_rounded, color: AppColors.cyan),
        children: [
          EvidenceTable(items: core.releaseReadiness.evidence),
          const SizedBox(height: 14),
          ClaimList(claims: core.protectionClaims),
          if (core.lastLeakSelfTest != null) ...[
            const SizedBox(height: 14),
            for (final result in core.lastLeakSelfTest!.results)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${result.kind}: ${result.status} - ${result.message}',
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PolicyNotice extends StatelessWidget {
  const _PolicyNotice({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Panel(
      color: AppColors.surfaceWarm,
      borderColor: AppColors.warn.withValues(alpha: 0.36),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warn),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              strings.isGerman
                  ? 'Tor ist kein klassischer VPN. P2P/Torrenting, Streaming- und Gaming-Erwartungen werden nicht als Use Case unterstuetzt.'
                  : 'Tor is not a classic VPN. P2P/torrenting, streaming, and gaming expectations are not supported use cases.',
            ),
          ),
        ],
      ),
    );
  }
}
