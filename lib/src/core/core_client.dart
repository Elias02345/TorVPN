import 'package:flutter/foundation.dart';

import 'core_models.dart';

/// The core surface the UI depends on, independent of how it is backed.
///
/// Two implementations exist:
///  * [MockCoreClient] - a pure-Dart development core used when the native
///    Rust library cannot be loaded (e.g. on platforms without a built cdylib).
///  * [FfiCoreClient] - the real Rust core (`tor_tunnel_core`) reached over the
///    versioned C ABI through `TorTunnelFfiLibrary`.
///
/// Keeping this as a `ChangeNotifier` lets the existing widgets rebuild via
/// `AnimatedBuilder` regardless of the backing implementation.
abstract class CoreClient extends ChangeNotifier {
  /// Country exit profiles offered to the user.
  List<CountryProfile> get profiles;

  /// Per-country exit relay availability shown on the Countries page.
  List<RelayCountryStatus> get relayCountries;

  /// Currently selected country profile.
  CountryProfile get selectedProfile;

  /// Strict vs. reduced-protection compatibility mode.
  ConnectionMode get connectionMode;

  /// Active bridge / pluggable-transport configuration.
  BridgeConfig get bridgeConfig;

  /// Latest connection status snapshot.
  ConnectionStatus get status;

  /// Result of the last exit verification, if any.
  ExitVerification? get lastVerification;

  /// Result of the last local leak self-test, if any.
  LeakSelfTestReport? get lastLeakSelfTest;

  bool get autoConnect;
  bool get autoRotation;
  bool get localVerboseDiagnostics;
  bool get onboardingDismissed;

  /// App exceptions (only meaningful in compatibility mode).
  List<AppException> get appExceptions;

  Future<void> connect();
  void disconnect();
  Future<void> rotateIdentity();

  void setSelectedProfile(CountryProfile profile);
  void setConnectionMode(ConnectionMode mode);
  void setBridgeConfig(BridgeConfig value);
  void setAutoConnect(bool value);
  void setAutoRotation(bool value);
  void setVerboseDiagnostics(bool value);
  void dismissOnboarding();
  void toggleAppException(String appId, bool enabled);

  ExitVerification verifyExit();
  String exportDiagnostics();
  LeakSelfTestReport runLeakSelfTest();
}
