import 'package:flutter/widgets.dart';

/// Lightweight, typed access to the two languages supported by FreshTrack.
///
/// Italian is used only when the resolved locale is Italian. Every other
/// system language is resolved to English by [FreshTrackApp].
class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  bool get isEnglish => locale.languageCode != 'it';
  String get languageCode => isEnglish ? 'en' : 'it';

  String text(String italian, String english) => isEnglish ? english : italian;
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings(Localizations.localeOf(this));
  String tr(String italian, String english) => strings.text(italian, english);
}
