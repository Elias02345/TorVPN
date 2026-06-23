import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// A country that hosts Tor exit relays, with an approximate centroid for the map.
class ExitCountry {
  const ExitCountry({
    required this.code,
    required this.name,
    required this.lat,
    required this.lon,
    required this.exitRelays,
    required this.available,
  });

  final String code;
  final String name;
  final double lat;
  final double lon;
  final int exitRelays;
  final bool available;

  factory ExitCountry.fromJson(Map<String, dynamic> json) {
    return ExitCountry(
      code: json['code'] as String,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      exitRelays: (json['exitRelays'] as num).toInt(),
      available: json['available'] as bool? ?? true,
    );
  }
}

/// Where a snapshot's data came from.
enum ExitDataSource { snapshot, liveOverTor }

/// A point-in-time view of exit-node availability per country.
class ExitDirectorySnapshot {
  const ExitDirectorySnapshot({
    required this.countries,
    required this.updated,
    required this.source,
    required this.dataSource,
  });

  final List<ExitCountry> countries;
  final String updated;
  final String source;
  final ExitDataSource dataSource;

  int get totalExitRelays =>
      countries.fold(0, (sum, country) => sum + country.exitRelays);

  int get availableCountries =>
      countries.where((country) => country.available).length;
}

/// Loads exit-node country data.
///
/// The directory ships a bundled snapshot so the map works offline and before
/// connecting. A live refresh is intentionally only performed *through Tor*
/// once the tunnel is up, so querying the directory never leaks to the clearnet
/// that a Tor client is running.
class ExitNodeDirectory {
  static const String _assetPath = 'assets/data/exit_countries.json';

  /// Load the snapshot bundled with the app.
  Future<ExitDirectorySnapshot> loadBundled() async {
    final raw = await rootBundle.loadString(_assetPath);
    return parse(raw, ExitDataSource.snapshot);
  }

  /// Parse a directory document. Exposed for testing and for the live path.
  static ExitDirectorySnapshot parse(String raw, ExitDataSource dataSource) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final countries =
        (json['countries'] as List)
            .map((entry) =>
                ExitCountry.fromJson((entry as Map).cast<String, dynamic>()))
            .toList()
          ..sort((a, b) => b.exitRelays.compareTo(a.exitRelays));
    return ExitDirectorySnapshot(
      countries: countries,
      updated: json['updated'] as String? ?? 'unknown',
      source: json['source'] as String? ?? '',
      dataSource: dataSource,
    );
  }

  /// Refresh from the Tor Project Onionoo service.
  ///
  /// Fail-closed: returns `null` unless the tunnel is active, so the request can
  /// be routed through Tor rather than leaking over the clearnet. The actual
  /// fetch is wired once the native tunnel is production-ready.
  Future<ExitDirectorySnapshot?> refreshOverTor({
    required bool tunnelActive,
  }) async {
    if (!tunnelActive) {
      return null;
    }
    // TODO(phase-4): fetch
    // https://onionoo.torproject.org/details?type=relay&flag=Exit&fields=country
    // through the Tor SOCKS proxy and aggregate exit counts per country.
    return null;
  }
}
