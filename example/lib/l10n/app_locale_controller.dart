import 'package:flutter/material.dart';

enum AppLocaleChoice { system, english, chinese }

class AppLocaleController {
  AppLocaleController._();

  static final AppLocaleController instance = AppLocaleController._();

  final ValueNotifier<AppLocaleChoice> choice = ValueNotifier<AppLocaleChoice>(
    AppLocaleChoice.system,
  );

  Locale? get locale {
    return switch (choice.value) {
      AppLocaleChoice.system => null,
      AppLocaleChoice.english => const Locale('en'),
      AppLocaleChoice.chinese => const Locale('zh'),
    };
  }

  void setChoice(AppLocaleChoice value) {
    choice.value = value;
  }
}
