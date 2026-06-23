import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/core_client.dart';
import '../core/exit_node_directory.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'shared.dart';

/// Project a geographic (lat, lon) onto an equirectangular canvas of [size].
Offset projectEquirectangular(double lat, double lon, Size size) {
  final dx = (lon + 180.0) / 360.0 * size.width;
  final dy = (90.0 - lat) / 180.0 * size.height;
  return Offset(dx, dy);
}

/// Marker radius scaled by the number of exit relays.
double exitMarkerRadius(int exitRelays) {
  final radius = 4.0 + math.sqrt(exitRelays.toDouble()) * 0.9;
  return radius.clamp(4.0, 20.0);
}

/// A clickable world map of Tor exit-node countries, plus a country list.
class WorldMapPage extends StatefulWidget {
  const WorldMapPage({required this.core, required this.strings, super.key});

  final CoreClient core;
  final AppStrings strings;

  @override
  State<WorldMapPage> createState() => _WorldMapPageState();
}

class _WorldMapPageState extends State<WorldMapPage> {
  final ExitNodeDirectory _directory = ExitNodeDirectory();
  late Future<ExitDirectorySnapshot> _future;
  ExitCountry? _selected;

  @override
  void initState() {
    super.initState();
    _future = _directory.loadBundled();
  }

  void _select(ExitCountry? country) => setState(() => _selected = country);

  void _handleTap(Offset local, Size size, List<ExitCountry> countries) {
    ExitCountry? nearest;
    var best = 28.0;
    for (final country in countries) {
      final point = projectEquirectangular(country.lat, country.lon, size);
      final distance = (point - local).distance;
      if (distance < best) {
        best = distance;
        nearest = country;
      }
    }
    if (nearest != null) {
      _select(nearest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return FutureBuilder<ExitDirectorySnapshot>(
      future: _future,
      builder: (context, snapshot) {
        return PageFrame(
          title: strings.countries,
          subtitle: strings.isGerman
              ? 'Weltkarte der Tor-Exit-Länder. Tippe einen Punkt an; Live-Update erfolgt über Tor, sobald verbunden.'
              : 'World map of Tor exit countries. Tap a point; live refresh runs over Tor once connected.',
          children: [
            if (!snapshot.hasData)
              InfoCard(
                child: Text(
                  snapshot.hasError
                      ? (strings.isGerman
                            ? 'Exit-Daten konnten nicht geladen werden.'
                            : 'Could not load exit data.')
                      : (strings.isGerman ? 'Lade Exit-Daten…' : 'Loading exit data…'),
                ),
              )
            else ...[
              _MapCard(
                data: snapshot.data!,
                selected: _selected,
                onTapMap: _handleTap,
                strings: strings,
                tunnelActive: widget.core.status.isActive,
              ),
              const SizedBox(height: 14),
              if (_selected != null) ...[
                _SelectedCountryCard(country: _selected!, strings: strings),
                const SizedBox(height: 14),
              ],
              _CountryList(
                data: snapshot.data!,
                selected: _selected,
                onSelect: _select,
                strings: strings,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.data,
    required this.selected,
    required this.onTapMap,
    required this.strings,
    required this.tunnelActive,
  });

  final ExitDirectorySnapshot data;
  final ExitCountry? selected;
  final void Function(Offset local, Size size, List<ExitCountry> countries)
  onTapMap;
  final AppStrings strings;
  final bool tunnelActive;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.public_rounded, color: AppColors.cyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.isGerman ? 'Exit-Node-Weltkarte' : 'Exit node world map',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusPill(
                icon: tunnelActive
                    ? Icons.cloud_sync_rounded
                    : Icons.public_off_rounded,
                label: tunnelActive
                    ? (strings.isGerman ? 'Live über Tor' : 'Live over Tor')
                    : (strings.isGerman ? 'Snapshot' : 'Snapshot'),
                color: tunnelActive ? AppColors.good : AppColors.cyan,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 2,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onTapUp: (details) =>
                        onTapMap(details.localPosition, size, data.countries),
                    child: CustomPaint(
                      painter: _WorldMapPainter(
                        countries: data.countries,
                        selectedCode: selected?.code,
                      ),
                      size: size,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendDot(
                color: AppColors.cyan,
                label: strings.isGerman ? 'Exits verfügbar' : 'Exits available',
              ),
              _LegendDot(
                color: AppColors.warn,
                label: strings.isGerman ? 'Keine Exits' : 'No exits',
              ),
              Text(
                '${data.availableCountries} ${strings.isGerman ? 'Länder' : 'countries'} · '
                '${data.totalExitRelays} ${strings.isGerman ? 'Exit-Relays' : 'exit relays'} · '
                '${data.updated}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _SelectedCountryCard extends StatelessWidget {
  const _SelectedCountryCard({required this.country, required this.strings});

  final ExitCountry country;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Row(
        children: [
          _CountryBadge(code: country.code),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  country.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  country.available
                      ? '${country.exitRelays} ${strings.isGerman ? 'Exit-Relays' : 'exit relays'}'
                      : (strings.isGerman
                            ? 'Derzeit keine Exit-Relays'
                            : 'No exit relays right now'),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          StatusPill(
            icon: country.available
                ? Icons.check_rounded
                : Icons.pause_rounded,
            label: country.available
                ? (strings.isGerman ? 'Verfügbar' : 'Available')
                : (strings.isGerman ? 'Keine Exits' : 'No exits'),
            color: country.available ? AppColors.good : AppColors.warn,
          ),
        ],
      ),
    );
  }
}

class _CountryList extends StatelessWidget {
  const _CountryList({
    required this.data,
    required this.selected,
    required this.onSelect,
    required this.strings,
  });

  final ExitDirectorySnapshot data;
  final ExitCountry? selected;
  final ValueChanged<ExitCountry> onSelect;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.isGerman ? 'Verfügbare Länder' : 'Available countries',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final country in data.countries)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelect(country),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: selected?.code == country.code
                      ? AppColors.cyan.withValues(alpha: 0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _CountryBadge(code: country.code, compact: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        country.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textHigh),
                      ),
                    ),
                    Text(
                      '${country.exitRelays}',
                      style: TextStyle(
                        color: country.available
                            ? AppColors.cyan
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      strings.isGerman ? 'Exits' : 'exits',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CountryBadge extends StatelessWidget {
  const _CountryBadge({required this.code, this.compact = false});

  final String code;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 52.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: AppColors.textHigh,
          fontSize: compact ? 13 : 18,
        ),
      ),
    );
  }
}

class _WorldMapPainter extends CustomPainter {
  _WorldMapPainter({required this.countries, required this.selectedCode});

  final List<ExitCountry> countries;
  final String? selectedCode;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = AppColors.surfaceLow);

    final grid = Paint()
      ..color = AppColors.border.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var lon = -150.0; lon <= 150.0; lon += 30.0) {
      final x = (lon + 180.0) / 360.0 * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var lat = -60.0; lat <= 60.0; lat += 30.0) {
      final y = (90.0 - lat) / 180.0 * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = AppColors.border
        ..strokeWidth = 1.3,
    );

    for (final country in countries) {
      final point = projectEquirectangular(country.lat, country.lon, size);
      final radius = exitMarkerRadius(country.exitRelays);
      final base = country.available ? AppColors.cyan : AppColors.warn;
      canvas.drawCircle(
        point,
        radius + 4,
        Paint()..color = base.withValues(alpha: 0.14),
      );
      canvas.drawCircle(
        point,
        radius,
        Paint()..color = base.withValues(alpha: 0.85),
      );
      canvas.drawCircle(
        point,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = base,
      );
      if (selectedCode == country.code) {
        canvas.drawCircle(
          point,
          radius + 6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = AppColors.textHigh,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WorldMapPainter oldDelegate) {
    return oldDelegate.selectedCode != selectedCode ||
        oldDelegate.countries != countries;
  }
}
