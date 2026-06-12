import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          ? 'Ein Button, ein Land, ein klarer Status.'
          : 'One button, one country, one clear status.',
      children: [
        _ConnectionPanel(core: core, strings: strings),
        const SizedBox(height: 14),
        _CountrySelector(core: core, strings: strings),
        const SizedBox(height: 14),
        _AlphaNotice(core: core, strings: strings),
      ],
    );
  }
}

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({required this.core, required this.strings});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final status = core.status;
    final active = status.isActive;
    final busy =
        status.state == ConnectionStateKind.connecting ||
        status.state == ConnectionStateKind.bootstrappingTor;
    final color = _statusColor(status);

    return Panel(
      padding: const EdgeInsets.all(22),
      color: AppColors.backgroundHigh,
      borderColor: color.withValues(alpha: 0.42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(
            icon: _statusIcon(status),
            label: _statusLabel(status, strings),
            color: color,
          ),
          const SizedBox(height: 18),
          Text(
            active
                ? (strings.isGerman ? 'VPN aktiv' : 'VPN active')
                : (strings.isGerman ? 'Nicht verbunden' : 'Not connected'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage(status, strings),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (busy) ...[
            const SizedBox(height: 18),
            LinearProgressIndicator(
              value: status.bootstrapPercent <= 0
                  ? null
                  : status.bootstrapPercent / 100,
              color: AppColors.cyan,
              backgroundColor: AppColors.surfaceHigh,
            ),
          ],
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const ValueKey('connect-button'),
                onPressed: busy
                    ? null
                    : active
                    ? core.disconnect
                    : () => core.connect(),
                icon: Icon(
                  active
                      ? Icons.power_settings_new_rounded
                      : Icons.vpn_lock_rounded,
                ),
                label: Text(active ? strings.disconnect : strings.connect),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: core.exportDiagnostics()),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          strings.isGerman
                              ? 'Diagnose kopiert.'
                              : 'Diagnostics copied.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.content_copy_rounded),
                label: Text(strings.exportDiagnostics),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(ConnectionStatus status) {
    return switch (status.state) {
      ConnectionStateKind.connected => AppColors.good,
      ConnectionStateKind.degraded => AppColors.warn,
      ConnectionStateKind.fallbackActive => AppColors.warn,
      ConnectionStateKind.connecting => AppColors.cyan,
      ConnectionStateKind.bootstrappingTor => AppColors.cyan,
      ConnectionStateKind.error => AppColors.danger,
      ConnectionStateKind.blockedByKillswitch => AppColors.warn,
      ConnectionStateKind.disconnected => AppColors.textMuted,
    };
  }

  IconData _statusIcon(ConnectionStatus status) {
    return switch (status.state) {
      ConnectionStateKind.connected => Icons.verified_rounded,
      ConnectionStateKind.degraded => Icons.warning_rounded,
      ConnectionStateKind.fallbackActive => Icons.warning_rounded,
      ConnectionStateKind.connecting => Icons.sync_rounded,
      ConnectionStateKind.bootstrappingTor => Icons.sync_rounded,
      ConnectionStateKind.error => Icons.error_rounded,
      ConnectionStateKind.blockedByKillswitch => Icons.lock_rounded,
      ConnectionStateKind.disconnected => Icons.radio_button_unchecked_rounded,
    };
  }

  String _statusLabel(ConnectionStatus status, AppStrings strings) {
    return switch (status.state) {
      ConnectionStateKind.connected =>
        strings.isGerman ? 'Verbunden' : 'Connected',
      ConnectionStateKind.degraded =>
        strings.isGerman ? 'Alpha aktiv' : 'Alpha active',
      ConnectionStateKind.fallbackActive =>
        strings.isGerman ? 'Fallback' : 'Fallback',
      ConnectionStateKind.connecting =>
        strings.isGerman ? 'Startet' : 'Starting',
      ConnectionStateKind.bootstrappingTor =>
        strings.isGerman ? 'Startet' : 'Starting',
      ConnectionStateKind.error => strings.isGerman ? 'Fehler' : 'Error',
      ConnectionStateKind.blockedByKillswitch =>
        strings.isGerman ? 'Blockiert' : 'Blocked',
      ConnectionStateKind.disconnected =>
        strings.isGerman ? 'Offline' : 'Offline',
    };
  }

  String _statusMessage(ConnectionStatus status, AppStrings strings) {
    if (status.message != 'Disconnected') {
      return status.message;
    }
    return strings.isGerman
        ? 'Tippe auf Verbinden. Auf Android fragt das System nach VPN-Erlaubnis.'
        : 'Tap Connect. On Android, the system will ask for VPN permission.';
  }
}

class _CountrySelector extends StatelessWidget {
  const _CountrySelector({required this.core, required this.strings});

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
                ? 'Auswahl ist eine Praeferenz, keine Garantie.'
                : 'Selection is a preference, not a guarantee.',
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: const ValueKey('country-select'),
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
              core.setSelectedProfile(
                core.profiles.firstWhere((profile) => profile.id == value),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(core.selectedProfile.description),
        ],
      ),
    );
  }
}

class _AlphaNotice extends StatelessWidget {
  const _AlphaNotice({required this.core, required this.strings});

  final CoreClient core;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final blockers = core.status.releaseBlockers;
    return Panel(
      color: AppColors.surfaceWarm,
      borderColor: AppColors.warn.withValues(alpha: 0.36),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_rounded, color: AppColors.warn),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              blockers.isEmpty
                  ? (strings.isGerman
                        ? 'Alpha: Android kann die VPN-Erlaubnis anfragen. Tor-Routing, Leak-Schutz und Stable-Release bleiben bis zur Verifikation eingeschraenkt.'
                        : 'Alpha: Android can request VPN permission. Tor routing, leak protection, and stable release remain limited until verified.')
                  : blockers.join('\n'),
            ),
          ),
        ],
      ),
    );
  }
}
