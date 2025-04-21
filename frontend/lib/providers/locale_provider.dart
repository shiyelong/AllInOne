import 'dart:ui';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class LocaleProvider with ChangeNotifier {
  bool _followSystem = true;
  Locale? _locale;

  LocaleProvider() {
    // 初始化语言设置
    _initLocale();
  }

  bool get followSystem => _followSystem;
  Locale? get locale => _locale;

  // 初始化语言设置
  Future<void> _initLocale() async {
    final savedLocale = await AppLocalizations.getSavedLocale();
    if (savedLocale != null) {
      _locale = savedLocale;
      _followSystem = false;
    } else {
      _followSystem = true;
      _locale = AppLocalizations.getDeviceLocale();
    }
    notifyListeners();
  }

  // 设置是否跟随系统语言
  Future<void> setFollowSystem(bool value) async {
    _followSystem = value;
    if (value) {
      // 如果跟随系统语言，则使用系统语言
      final systemLocale = AppLocalizations.getDeviceLocale();
      // 检查系统语言是否在支持列表中
      bool isSupported = AppLocalizations.supportedLocales
          .any((locale) => locale.languageCode == systemLocale.languageCode);
      
      // 如果系统语言不支持，使用中文
      _locale = isSupported ? systemLocale : const Locale('zh', 'CN');
      await AppLocalizations.saveLocale(_locale!);
    } else if (_locale == null) {
      // 如果关闭跟随系统，但没有设置语言，默认使用中文
      _locale = const Locale('zh', 'CN');
      await AppLocalizations.saveLocale(_locale!);
    }
    notifyListeners();
  }

  // 设置用户选择的语言
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    _followSystem = false;
    await AppLocalizations.saveLocale(locale);
    notifyListeners();
  }

  // 获取实际使用的语言(考虑跟随系统的情况)
  Locale? getLocale() {
    if (_followSystem) {
      return AppLocalizations.getDeviceLocale();
    }
    return _locale;
  }
}
