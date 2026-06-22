import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tortunnel/src/core/ffi_core_client.dart';

/// Exercises the real Dart -> FFI -> Rust core -> Dart round-trip against the
/// host cdylib. The cdylib is built by `cargo build -p tor_tunnel_core`
/// (Windows: tor_tunnel_core.dll, Linux: libtor_tunnel_core.so). When it is not
/// present - e.g. on the CI Flutter job, which does not build Rust - the test
/// is skipped rather than failed.
String? _hostCdylibPath() {
  final candidates = <String>[
    if (Platform.isWindows) 'target/debug/tor_tunnel_core.dll',
    if (Platform.isWindows) 'target/release/tor_tunnel_core.dll',
    if (Platform.isLinux) 'target/debug/libtor_tunnel_core.so',
    if (Platform.isLinux) 'target/release/libtor_tunnel_core.so',
    if (Platform.isMacOS) 'target/debug/libtor_tunnel_core.dylib',
  ];
  for (final candidate in candidates) {
    if (File(candidate).existsSync()) {
      return File(candidate).absolute.path;
    }
  }
  return null;
}

void main() {
  test('native core FFI round-trip mirrors the Rust contract', () {
    final path = _hostCdylibPath();
    if (path == null) {
      markTestSkipped('Host cdylib not built; run `cargo build -p tor_tunnel_core`.');
      return;
    }

    final library = TorTunnelFfiLibrary.fromPath(path);
    final session = library.createSession();
    addTearDown(session.close);

    final connect = session.connect({
      'platform': Platform.isWindows ? 'windows' : 'linux',
      'mode': 'compatibility-reduced-protection',
      'profile': {
        'id': 'eu-privacy',
        'name': 'EU Privacy',
        'exit_countries': ['DE', 'NL'],
        'preference_mode': 'prefer',
      },
      'bridge_config': {'kind': 'none'},
      'app_exceptions': <Map<String, dynamic>>[],
      'auto_fallback': true,
      'isolate_by_app': true,
    });

    expect(connect['protocol_version'], 1);
    expect(connect['ok'], isTrue);

    final status = (connect['payload'] as Map).cast<String, dynamic>();
    // Leak-protection defaults are fail-closed in the core contract.
    expect(status['udp_blocked'], isTrue);
    expect(status['ipv6_blocked'], isTrue);
    expect(status['kill_switch_active'], isTrue);

    // Diagnostics expose the generated torrc, proving config generation works.
    final diagnostics = session.exportDiagnostics();
    final bundle = (diagnostics['payload'] as Map).cast<String, dynamic>();
    expect(bundle['tor_config_preview'], contains('DNSPort 127.0.0.1:5353'));
    expect(bundle['tor_config_preview'], contains('ExitNodes {DE},{NL}'));

    // Strict-mode self-test must refuse a stable release while scaffolded.
    final leak = session.runLeakSelfTest();
    final report = (leak['payload'] as Map).cast<String, dynamic>();
    expect(report['stable_release_allowed'], isFalse);
  });
}
