import 'package:flutter/material.dart';

enum AppLanguage { en, pl }

class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(AppLanguage.en);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Generic
  String get appTitle => _t('appTitle');
  String get events => _t('events');
  String get details => _t('details');
  String get live => _t('live');
  String get offline => _t('offline');
  String get noEventsYet => _t('noEventsYet');
  String get settings => _t('settings');
  String get languageLabel => _t('language');
  String get english => _t('english');
  String get polish => _t('polish');

  // Contractions
  String get contractions => _t('contractions');
  String get noContractionsInPeriod => _t('noContractionsInPeriod');
  String get startContraction => _t('startContraction');
  String get stopContraction => _t('stopContraction');
  String get contractionRecorded => _t('contractionRecorded');
  String get startContractionToSeeTimeline => _t('startContractionToSeeTimeline');

  // Time periods
  String get now => _t('now');
  String get hoursAgo => _t('hoursAgo');
  String inLastHours(int hours) => _t('inLastHours').replaceAll('{hours}', hours.toString());
  String hoursAbbrev(int hours) => '${hours}h';

  // Vital stats
  String get avgDuration => _t('avgDuration');
  String get avgGap => _t('avgGap');
  String get frequency => _t('frequency');
  String inPeriod(String period) => _t('inPeriod').replaceAll('{period}', period);

  // Events
  String get otherEvents => _t('otherEvents');
  String get noOtherEvents => _t('noOtherEvents');
  String get symptomReported => _t('symptomReported');
  String get reportSymptomsToMidwife => _t('reportSymptomsToMidwife');

  // Symptoms
  String get watersBreaking => _t('watersBreaking');
  String get bleeding => _t('bleeding');
  String get mucusPlug => _t('mucusPlug');
  String get reducedMovement => _t('reducedMovement');
  String get nausea => _t('nausea');
  String get visionIssues => _t('visionIssues');
  String get feverChills => _t('feverChills');

  // Labor events
  String get watersHaveBroken => _t('watersHaveBroken');
  String get bleedingReported => _t('bleedingReported');
  String get mucusPlugPassed => _t('mucusPlugPassed');
  String get reducedFetalMovement => _t('reducedFetalMovement');
  String get nauseaReported => _t('nauseaReported');
  String get headacheVisionIssues => _t('headacheVisionIssues');
  String get feverChillsReported => _t('feverChillsReported');
  String get laborEventReported => _t('laborEventReported');

  // Status
  String get connected => _t('connected');
  String get pending => _t('pending');
  String get syncNow => _t('syncNow');
  String get syncFailed => _t('syncFailed');
  String get caseLabel => _t('caseLabel');

  // PIN
  String get createPin => _t('createPin');
  String get confirmPin => _t('confirmPin');
  String get createPinDescription => _t('createPinDescription');
  String get pinSecurityNote => _t('pinSecurityNote');
  String get enterPin => _t('enterPin');
  String get enterPinDescription => _t('enterPinDescription');
  String get incorrectPin => _t('incorrectPin');
  String get tooManyAttempts => _t('tooManyAttempts');
  String attemptsRemaining(int count) => _t('attemptsRemaining').replaceAll('{count}', count.toString());

  String _t(String key) {
    return _translations[language]?[key] ?? _translations[AppLanguage.en]![key] ?? key;
  }

  static final Map<AppLanguage, Map<String, String>> _translations = {
    AppLanguage.en: {
      'appTitle': 'Birth Journal',
      'events': 'Events',
      'details': 'Details',
      'live': 'Live',
      'offline': 'Offline',
      'noEventsYet': 'No events yet',
      'settings': 'Settings',
      'language': 'Language',
      'english': 'English',
      'polish': 'Polski',
      
      // Contractions
      'contractions': 'Contractions',
      'noContractionsInPeriod': 'No contractions in this period',
      'startContraction': 'START CONTRACTION',
      'stopContraction': 'STOP CONTRACTION',
      'contractionRecorded': 'Contraction recorded',
      'startContractionToSeeTimeline': 'Start a contraction to see the timeline',
      
      // Time
      'now': 'now',
      'hoursAgo': 'h ago',
      'inLastHours': 'in last {hours}h',
      
      // Stats
      'avgDuration': 'Avg Duration',
      'avgGap': 'Avg Gap',
      'frequency': 'Frequency',
      'inPeriod': 'in {period}',
      
      // Events
      'otherEvents': 'Other Events',
      'noOtherEvents': 'No other events',
      'symptomReported': 'Symptom reported to midwife',
      'reportSymptomsToMidwife': 'Report symptoms to your midwife',
      
      // Symptoms
      'watersBreaking': 'Waters breaking',
      'bleeding': 'Bleeding',
      'mucusPlug': 'Mucus plug',
      'reducedMovement': 'Reduced movement',
      'nausea': 'Nausea',
      'visionIssues': 'Vision issues',
      'feverChills': 'Fever/chills',
      
      // Labor events
      'watersHaveBroken': 'Waters have broken',
      'bleedingReported': 'Bleeding reported',
      'mucusPlugPassed': 'Mucus plug passed',
      'reducedFetalMovement': 'Reduced fetal movement reported',
      'nauseaReported': 'Nausea reported',
      'headacheVisionIssues': 'Headache/vision issues reported',
      'feverChillsReported': 'Fever or chills reported',
      'laborEventReported': 'Labor event reported',
      
      // Status
      'connected': 'Connected',
      'pending': 'pending',
      'syncNow': 'Sync now',
      'syncFailed': 'Sync failed',
      'caseLabel': 'Case',
      
      // PIN
      'createPin': 'Create PIN',
      'confirmPin': 'Confirm your PIN',
      'createPinDescription': 'Create a 4-digit PIN to secure your data',
      'pinSecurityNote': 'This PIN protects access to your birth journal. Keep it safe and do not share it.',
      'enterPin': 'Enter PIN',
      'enterPinDescription': 'Enter your 4-digit PIN to access the app',
      'incorrectPin': 'Incorrect PIN',
      'tooManyAttempts': 'Too many incorrect attempts',
      'attemptsRemaining': '{count} attempts remaining',
    },
    AppLanguage.pl: {
      'appTitle': 'Dziennik Porodu',
      'events': 'Zdarzenia',
      'details': 'Szczegóły',
      'live': 'Online',
      'offline': 'Offline',
      'noEventsYet': 'Brak zdarzeń',
      'settings': 'Ustawienia',
      'language': 'Język',
      'english': 'English',
      'polish': 'Polski',
      
      // Contractions
      'contractions': 'Skurcze',
      'noContractionsInPeriod': 'Brak skurczów w tym okresie',
      'startContraction': 'ROZPOCZNIJ SKURCZ',
      'stopContraction': 'ZAKOŃCZ SKURCZ',
      'contractionRecorded': 'Skurcz zapisany',
      'startContractionToSeeTimeline': 'Rozpocznij skurcz, aby zobaczyć oś czasu',
      
      // Time
      'now': 'teraz',
      'hoursAgo': 'h temu',
      'inLastHours': 'w ostatnich {hours}h',
      
      // Stats
      'avgDuration': 'Śr. czas',
      'avgGap': 'Śr. przerwa',
      'frequency': 'Częstość',
      'inPeriod': 'w {period}',
      
      // Events
      'otherEvents': 'Inne zdarzenia',
      'noOtherEvents': 'Brak innych zdarzeń',
      'symptomReported': 'Objaw zgłoszony położnej',
      'reportSymptomsToMidwife': 'Zgłoś objawy położnej',
      
      // Symptoms
      'watersBreaking': 'Odejście wód',
      'bleeding': 'Krwawienie',
      'mucusPlug': 'Czop śluzowy',
      'reducedMovement': 'Osłabione ruchy',
      'nausea': 'Nudności',
      'visionIssues': 'Problemy ze wzrokiem',
      'feverChills': 'Gorączka/dreszcze',
      
      // Labor events
      'watersHaveBroken': 'Odeszły wody płodowe',
      'bleedingReported': 'Zgłoszono krwawienie',
      'mucusPlugPassed': 'Odszedł czop śluzowy',
      'reducedFetalMovement': 'Zgłoszono osłabione ruchy płodu',
      'nauseaReported': 'Zgłoszono nudności',
      'headacheVisionIssues': 'Zgłoszono ból głowy/problemy ze wzrokiem',
      'feverChillsReported': 'Zgłoszono gorączkę lub dreszcze',
      'laborEventReported': 'Zgłoszono zdarzenie porodowe',
      
      // Status
      'connected': 'Połączono',
      'pending': 'oczekuje',
      'syncNow': 'Synchronizuj',
      'syncFailed': 'Synchronizacja nieudana',
      'caseLabel': 'Przypadek',
      
      // PIN
      'createPin': 'Utwórz PIN',
      'confirmPin': 'Potwierdź PIN',
      'createPinDescription': 'Utwórz 4-cyfrowy PIN, aby zabezpieczyć swoje dane',
      'pinSecurityNote': 'Ten PIN chroni dostęp do Twojego dziennika porodu. Zachowaj go w bezpiecznym miejscu.',
      'enterPin': 'Wprowadź PIN',
      'enterPinDescription': 'Wprowadź 4-cyfrowy PIN, aby uzyskać dostęp do aplikacji',
      'incorrectPin': 'Nieprawidłowy PIN',
      'tooManyAttempts': 'Zbyt wiele nieudanych prób',
      'attemptsRemaining': 'Pozostało prób: {count}',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'pl'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final lang = locale.languageCode == 'pl' ? AppLanguage.pl : AppLanguage.en;
    return AppLocalizations(lang);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Language provider for state management
class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.en;

  AppLanguage get language => _language;

  void setLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners();
  }

  Locale get locale => Locale(_language == AppLanguage.pl ? 'pl' : 'en');
}
