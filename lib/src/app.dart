import 'package:flutter/material.dart';

import 'core/core_models.dart';
import 'core/mock_core_client.dart';
import 'features/activity_page.dart';
import 'features/app_exceptions_page.dart';
import 'features/countries_page.dart';
import 'features/home_page.dart';
import 'features/settings_page.dart';
import 'l10n/app_strings.dart';
import 'theme/app_theme.dart';

class TorTunnelApp extends StatefulWidget {
  const TorTunnelApp({super.key});

  @override
  State<TorTunnelApp> createState() => _TorTunnelAppState();
}

class _TorTunnelAppState extends State<TorTunnelApp> {
  final MockCoreClient _core = MockCoreClient();
  LanguageChoice _language = LanguageChoice.de;

  @override
  void dispose() {
    _core.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.forLanguage(_language);

    return MaterialApp(
      title: 'TorTunnel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: AnimatedBuilder(
        animation: _core,
        builder: (context, _) {
          return TorTunnelShell(
            core: _core,
            strings: strings,
            language: _language,
            onLanguageChanged: (language) {
              setState(() => _language = language);
            },
          );
        },
      ),
    );
  }
}

class TorTunnelShell extends StatefulWidget {
  const TorTunnelShell({
    required this.core,
    required this.strings,
    required this.language,
    required this.onLanguageChanged,
    super.key,
  });

  final MockCoreClient core;
  final AppStrings strings;
  final LanguageChoice language;
  final ValueChanged<LanguageChoice> onLanguageChanged;

  @override
  State<TorTunnelShell> createState() => _TorTunnelShellState();
}

class _TorTunnelShellState extends State<TorTunnelShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final destinations = [
      _Destination(Icons.power_settings_new_rounded, widget.strings.home),
      _Destination(Icons.public_rounded, widget.strings.countries),
      _Destination(Icons.apps_rounded, widget.strings.appExceptions),
      _Destination(Icons.timeline_rounded, widget.strings.activity),
      _Destination(Icons.tune_rounded, widget.strings.settings),
    ];

    final pages = [
      HomePage(core: widget.core, strings: widget.strings),
      CountriesPage(core: widget.core, strings: widget.strings),
      AppExceptionsPage(core: widget.core, strings: widget.strings),
      ActivityPage(core: widget.core, strings: widget.strings),
      SettingsPage(
        core: widget.core,
        strings: widget.strings,
        language: widget.language,
        onLanguageChanged: widget.onLanguageChanged,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (wide)
                  _SideRail(
                    destinations: destinations,
                    selectedIndex: _selectedIndex,
                    onSelected: (index) =>
                        setState(() => _selectedIndex = index),
                  ),
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                    ),
                    child: IndexedStack(index: _selectedIndex, children: pages),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  destinations: [
                    for (final destination in destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        label: destination.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 20),
      color: AppColors.surfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(Icons.route_rounded, color: AppColors.cyan),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'TorTunnel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          for (var index = 0; index < destinations.length; index++)
            _RailButton(
              destination: destinations[index],
              selected: index == selectedIndex,
              onTap: () => onSelected(index),
            ),
          const Spacer(),
          const _TrustFooter(),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Tooltip(
        message: destination.label,
        child: Material(
          color: selected
              ? AppColors.cyan.withValues(alpha: 0.13)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    destination.icon,
                    color: selected ? AppColors.cyan : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? AppColors.textHigh
                            : AppColors.textMuted,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustFooter extends StatelessWidget {
  const _TrustFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: AppColors.good, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No backend. No accounts. Local diagnostics only.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.icon, this.label);

  final IconData icon;
  final String label;
}
