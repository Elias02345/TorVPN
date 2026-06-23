import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:tortunnel/src/core/exit_node_directory.dart';
import 'package:tortunnel/src/features/world_map_page.dart';

const _sample = '''
{
  "updated": "2026-06-23",
  "source": "test",
  "countries": [
    { "code": "NL", "name": "Netherlands", "lat": 52.1, "lon": 5.3, "exitRelays": 372, "available": true },
    { "code": "DE", "name": "Germany", "lat": 51.2, "lon": 10.4, "exitRelays": 438, "available": true },
    { "code": "IS", "name": "Iceland", "lat": 64.9, "lon": -19.0, "exitRelays": 0, "available": false }
  ]
}
''';

void main() {
  group('ExitNodeDirectory.parse', () {
    test('sorts countries by exit relays descending', () {
      final snapshot = ExitNodeDirectory.parse(_sample, ExitDataSource.snapshot);
      expect(snapshot.countries.first.code, 'DE');
      expect(snapshot.countries.map((c) => c.code).toList(), ['DE', 'NL', 'IS']);
    });

    test('aggregates totals and availability', () {
      final snapshot = ExitNodeDirectory.parse(_sample, ExitDataSource.snapshot);
      expect(snapshot.totalExitRelays, 810);
      expect(snapshot.availableCountries, 2);
      expect(snapshot.updated, '2026-06-23');
    });
  });

  test('refreshOverTor is fail-closed without an active tunnel', () async {
    final result = await ExitNodeDirectory().refreshOverTor(tunnelActive: false);
    expect(result, isNull);
  });

  group('equirectangular projection', () {
    const size = Size(360, 180);

    test('maps the origin to the canvas center', () {
      final point = projectEquirectangular(0, 0, size);
      expect(point.dx, closeTo(180, 0.001));
      expect(point.dy, closeTo(90, 0.001));
    });

    test('maps the top-left geographic corner to (0, 0)', () {
      final point = projectEquirectangular(90, -180, size);
      expect(point.dx, closeTo(0, 0.001));
      expect(point.dy, closeTo(0, 0.001));
    });

    test('marker radius grows with exit count but is clamped', () {
      expect(exitMarkerRadius(0), 4.0);
      expect(exitMarkerRadius(400) > exitMarkerRadius(40), isTrue);
      expect(exitMarkerRadius(100000), 20.0);
    });
  });
}
