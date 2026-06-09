import '../core/core_models.dart';

class AppStrings {
  const AppStrings._(this.language);

  final LanguageChoice language;

  static AppStrings forLanguage(LanguageChoice language) =>
      AppStrings._(language);

  bool get isGerman => language == LanguageChoice.de;

  String get home => isGerman ? 'Start' : 'Home';
  String get countries => isGerman ? 'Länder' : 'Countries';
  String get appExceptions => isGerman ? 'App-Ausnahmen' : 'App exceptions';
  String get activity => isGerman ? 'Aktivität' : 'Activity';
  String get settings => isGerman ? 'Einstellungen' : 'Settings';
  String get mode => isGerman ? 'Modus' : 'Mode';
  String get strictMode => isGerman ? 'Strict Mode' : 'Strict Mode';
  String get compatibilityMode => isGerman ? 'Kompatibilität' : 'Compatibility';
  String get reducedProtection =>
      isGerman ? 'Reduzierter Schutz' : 'Reduced protection';
  String get bridges => isGerman ? 'Bridges' : 'Bridges';
  String get leakSelfTest => isGerman ? 'Leak-Selbsttest' : 'Leak self-test';
  String get releaseBlockers => isGerman ? 'Stable-Blocker' : 'Stable blockers';
  String get connect => isGerman ? 'Verbinden' : 'Connect';
  String get disconnect => isGerman ? 'Trennen' : 'Disconnect';
  String get newIdentity => isGerman ? 'Neue Identität' : 'New identity';
  String get verifyExit => isGerman ? 'Exit prüfen' : 'Verify exit';
  String get exportDiagnostics =>
      isGerman ? 'Diagnose exportieren' : 'Export diagnostics';
  String get preferredExitCountries =>
      isGerman ? 'Bevorzugte Exit-Länder' : 'Preferred exit countries';
  String get protectionStatus =>
      isGerman ? 'Schutzstatus' : 'Protection status';
  String get localOnly =>
      isGerman ? 'Lokal, kein Backend' : 'Local, no backend';
  String get torLimitsTitle =>
      isGerman ? 'Tor ist kein klassischer VPN' : 'Tor is not a classic VPN';
  String get torLimitsBody => isGerman
      ? 'TorTunnel leitet TCP und DNS über Tor, blockiert UDP/IPv6 im MVP und warnt vor P2P, Streaming- und Gaming-Erwartungen.'
      : 'TorTunnel routes TCP and DNS through Tor, blocks UDP/IPv6 in the MVP, and warns about P2P, streaming, and gaming expectations.';
  String get scaffoldMode => isGerman
      ? 'Scaffold-Modus: native Tunneladapter müssen noch produktionsreif implementiert werden.'
      : 'Scaffold mode: native tunnel adapters still need production implementation.';
  String get noTelemetry => isGerman ? 'Keine Telemetrie' : 'No telemetry';
  String get signedReleases =>
      isGerman ? 'Signierte Releases' : 'Signed releases';
  String get manualCrashReports =>
      isGerman ? 'Manuelle Crash-Reports' : 'Manual crash reports';
  String get autoConnect =>
      isGerman ? 'Auto-Connect optional' : 'Optional auto-connect';
  String get autoRotation => isGerman ? 'Auto-Rotation' : 'Auto-rotation';
  String get languageLabel => isGerman ? 'Sprache' : 'Language';
}
