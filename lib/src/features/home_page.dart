import 'package:flutter/material.dart';

import '../core/core_models.dart';
import '../core/mock_core_client.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'shared.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.core, required this.strings, super.key});

  final MockCoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'TorTunnel',
      subtitle: strings.isGerman
          ? 'Systemweiter Tor-Tunnel mit Länderpräferenzen und strengem Leak-Schutz.'
          : 'System-wide Tor tunnel with country preferences and strict leak protection.',
      children: [
        if (!core.onboardingDismissed) ...[
          _OnboardingNotice(core: core, strings: strings),
          const SizedBox(height: 14),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final hero = _ConnectionHero(core: core, strings: strings);
            final profile = _ProfilePanel(core: core, strings: strings);
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: hero),
                  const SizedBox(width: 14),
                  Expanded(flex: 4, child: profile),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [hero, const SizedBox(height: 14), profile],
            );
          },
        ),
        const SizedBox(height: 14),
        _ProtectionGrid(core: core, strings: strings),
        const SizedBox(height: 14),
        if (core.status.releaseBlockers.isNotEmpty) ...[
          _ReleaseBlockers(core: core, strings: strings),
          const SizedBox(height: 14),
        ],
        _PolicyNotice(strings: strings),
      ],
    );
  }
}

class _OnboardingNotice extends StatelessWidget {
  const _OnboardingNotice({required this.core, required this.strings});

  final MockCoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
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

class _ConnectionHero extends StatelessWidget {
  const _ConnectionHero({required this.core, required this.strings});

  final MockCoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final status = core.status;
    final active = status.isActive;
    final stateLabel = _stateLabel(status.state, strings);
    final buttonIcon = active ? Icons.stop_rounded : Icons.play_arrow_rounded;
    final buttonLabel = active ? strings.disconnect : strings.connect;

    return InfoCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                icon: active ? Icons.shield_rounded : Icons.shield_outlined,
                label: stateLabel,
                color: status.health == TunnelHealth.protected
                    ? AppColors.good
                    : AppColors.warn,
              ),
              StatusPill(
                icon: status.mode == ConnectionMode.strict
                    ? Icons.lock_rounded
                    : Icons.warning_rounded,
                label: status.mode == ConnectionMode.strict
                    ? strings.strictMode
                    : strings.reducedProtection,
                color: status.mode == ConnectionMode.strict
                    ? AppColors.cyan
                    : AppColors.warn,
              ),
              StatusPill(
                icon: Icons.cloud_off_rounded,
                label: strings.localOnly,
                color: AppColors.cyan,
              ),
              if (status.state == ConnectionStateKind.degraded)
                StatusPill(
                  icon: Icons.construction_rounded,
                  label: strings.isGerman ? 'Scaffold' : 'Scaffold',
                  color: AppColors.warn,
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            status.health == TunnelHealth.protected
                ? (strings.isGerman ? 'Tor-Tunnel aktiv' : 'Tor tunnel active')
                : status.health == TunnelHealth.blockedByKillSwitch
                ? (strings.isGerman
                      ? 'Kill-Switch blockiert'
                      : 'Kill switch blocking')
                : (strings.isGerman
                      ? 'Bereit zum Verbinden'
                      : 'Ready to connect'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(status.message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: status.bootstrapPercent / 100,
              minHeight: 9,
              backgroundColor: AppColors.surfaceHigh,
              color: active ? AppColors.good : AppColors.cyan,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const ValueKey('connect-button'),
                onPressed: active ? core.disconnect : core.connect,
                icon: Icon(buttonIcon),
                label: Text(buttonLabel),
              ),
              OutlinedButton.icon(
                onPressed: active ? core.rotateIdentity : null,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(strings.newIdentity),
              ),
              OutlinedButton.icon(
                onPressed: core.verifyExit,
                icon: const Icon(Icons.travel_explore_rounded),
                label: Text(strings.verifyExit),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _stateLabel(ConnectionStateKind state, AppStrings strings) {
    switch (state) {
      case ConnectionStateKind.disconnected:
        return strings.isGerman ? 'Getrennt' : 'Disconnected';
      case ConnectionStateKind.connecting:
        return strings.isGerman ? 'Verbindet' : 'Connecting';
      case ConnectionStateKind.bootstrappingTor:
        return strings.isGerman ? 'Tor startet' : 'Bootstrapping Tor';
      case ConnectionStateKind.connected:
        return strings.isGerman ? 'Verbunden' : 'Connected';
      case ConnectionStateKind.degraded:
        return strings.isGerman ? 'Degradiert' : 'Degraded';
      case ConnectionStateKind.fallbackActive:
        return strings.isGerman ? 'Fallback aktiv' : 'Fallback active';
      case ConnectionStateKind.blockedByKillswitch:
        return strings.isGerman ? 'Kill-Switch' : 'Kill switch';
      case ConnectionStateKind.error:
        return strings.isGerman ? 'Fehler' : 'Error';
    }
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.core, required this.strings});

  final MockCoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.preferredExitCountries,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: core.selectedProfile.id,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: [
              for (final profile in core.profiles)
                DropdownMenuItem(value: profile.id, child: Text(profile.name)),
            ],
            onChanged: (value) {
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

class _ProtectionGrid extends StatelessWidget {
  const _ProtectionGrid({required this.core, required this.strings});

  final MockCoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final status = core.status;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 860 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: columns == 4 ? 2.65 : 1.75,
          children: [
            MetricTile(
              icon: Icons.lock_rounded,
              label: strings.isGerman ? 'Kill-Switch' : 'Kill switch',
              value: status.killSwitchActive ? 'Active' : 'Idle',
              color: status.killSwitchActive ? AppColors.good : AppColors.warn,
            ),
            MetricTile(
              icon: Icons.dns_rounded,
              label: strings.isGerman ? 'DNS über Tor' : 'DNS over Tor',
              value: status.dnsProtected ? 'Protected' : 'Off',
              color: status.dnsProtected ? AppColors.good : AppColors.warn,
            ),
            MetricTile(
              icon: Icons.block_rounded,
              label: strings.isGerman ? 'UDP blockiert' : 'UDP blocked',
              value: status.udpBlocked ? 'Blocked' : 'Allowed',
              color: status.udpBlocked ? AppColors.good : AppColors.danger,
            ),
            MetricTile(
              icon: Icons.hub_rounded,
              label: strings.isGerman ? 'IPv6 im MVP' : 'IPv6 in MVP',
              value: status.ipv6Blocked ? 'Blocked' : 'Allowed',
              color: status.ipv6Blocked ? AppColors.good : AppColors.danger,
            ),
          ],
        );
      },
    );
  }
}

class _ReleaseBlockers extends StatelessWidget {
  const _ReleaseBlockers({required this.core, required this.strings});

  final MockCoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gpp_bad_rounded, color: AppColors.warn),
              const SizedBox(width: 10),
              Text(
                strings.releaseBlockers,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final blocker in core.status.releaseBlockers)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('- $blocker'),
            ),
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
    return InfoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warn),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              strings.isGerman
                  ? 'P2P/Torrenting wird nicht als Anwendungsfall unterstützt. App-Ausnahmen muessen bewusst aktiviert werden und koennen Datenschutz reduzieren.'
                  : 'P2P/torrenting is not a supported use case. App exceptions must be enabled deliberately and can reduce privacy.',
            ),
          ),
        ],
      ),
    );
  }
}
