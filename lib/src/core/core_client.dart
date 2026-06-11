import 'package:flutter/foundation.dart';

import 'core_models.dart';

abstract class CoreClient extends ChangeNotifier {
  List<CountryProfile> get profiles;
  List<RelayCountryStatus> get relayCountries;
  List<AppException> get appExceptions;

  CountryProfile get selectedProfile;
  ConnectionMode get connectionMode;
  BridgeConfig get bridgeConfig;
  ConnectionStatus get status;
  ReleaseReadiness get releaseReadiness;
  List<ProtectionClaim> get protectionClaims;
  ExitVerification? get lastVerification;
  LeakSelfTestReport? get lastLeakSelfTest;

  bool get autoConnect;
  bool get autoRotation;
  bool get localVerboseDiagnostics;
  bool get onboardingDismissed;

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
