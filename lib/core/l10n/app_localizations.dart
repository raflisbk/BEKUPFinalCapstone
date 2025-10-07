import 'package:flutter/material.dart';
import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

/// App localizations delegate for multi-language support
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// Get instance from context
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('id', 'ID'), // Indonesian
  ];

  /// Localization delegates
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Get translations based on current locale
  Map<String, String> get _translations {
    switch (locale.languageCode) {
      case 'id':
        return AppLocalizationsId.translations;
      case 'en':
      default:
        return AppLocalizationsEn.translations;
    }
  }

  /// Get translated string
  String translate(String key) {
    return _translations[key] ?? key;
  }

  // Common translations with getters for easy access
  String get appName => translate('app_name');
  String get welcome => translate('welcome');
  String get login => translate('login');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get forgotPassword => translate('forgot_password');
  String get dontHaveAccount => translate('dont_have_account');
  String get alreadyHaveAccount => translate('already_have_account');

  // Navigation
  String get home => translate('home');
  String get explore => translate('explore');
  String get trips => translate('trips');
  String get chat => translate('chat');
  String get profile => translate('profile');

  // Actions
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get share => translate('share');
  String get search => translate('search');
  String get filter => translate('filter');
  String get sort => translate('sort');
  String get submit => translate('submit');
  String get confirm => translate('confirm');

  // Messages
  String get loading => translate('loading');
  String get noData => translate('no_data');
  String get error => translate('error');
  String get success => translate('success');
  String get warning => translate('warning');

  // Trip related
  String get createTrip => translate('create_trip');
  String get tripName => translate('trip_name');
  String get startDate => translate('start_date');
  String get endDate => translate('end_date');
  String get destination => translate('destination');
  String get participants => translate('participants');
  String get itinerary => translate('itinerary');
  String get budget => translate('budget');

  // Chat related
  String get sendMessage => translate('send_message');
  String get typeMessage => translate('type_message');
  String get noMessages => translate('no_messages');
  String get online => translate('online');
  String get offline => translate('offline');

  // Review related
  String get writeReview => translate('write_review');
  String get rating => translate('rating');
  String get reviewTitle => translate('review_title');
  String get reviewContent => translate('review_content');

  // Settings
  String get settings => translate('settings');
  String get language => translate('language');
  String get darkMode => translate('dark_mode');
  String get notifications => translate('notifications');
  String get privacy => translate('privacy');
  String get termsOfService => translate('terms_of_service');
  String get logout => translate('logout');
}

/// Localizations delegate
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'id'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
