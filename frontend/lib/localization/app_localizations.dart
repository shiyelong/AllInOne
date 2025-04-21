import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};
  static const String _prefsLanguageCode = 'languageCode';
  static const String _prefsCountryCode = 'countryCode';
  
  AppLocalizations(this.locale);

  // 辅助方法，加载当前语言的JSON文件
  Future<bool> loadTranslations() async {
    String jsonString = await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    
    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
    
    return true;
  }
  
  // 用于访问本地化字符串的方法
  String translate(String key, {Map<String, String>? args}) {
    String value = _localizedStrings[key] ?? key;
    
    if (args != null) {
      args.forEach((argKey, argValue) {
        value = value.replaceAll('{$argKey}', argValue);
      });
    }
    
    return value;
  }
  
  // 获取系统语言
  static Locale getDeviceLocale() {
    return WidgetsBinding.instance.platformDispatcher.locale;
  }
  
  // 从首选项中获取保存的语言
  static Future<Locale?> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_prefsLanguageCode);
    final countryCode = prefs.getString(_prefsCountryCode);
    
    if (languageCode != null) {
      return Locale(languageCode, countryCode);
    }
    
    return null;
  }
  
  // 保存语言设置
  static Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsLanguageCode, locale.languageCode);
    if (locale.countryCode != null) {
      await prefs.setString(_prefsCountryCode, locale.countryCode!);
    } else {
      await prefs.remove(_prefsCountryCode);
    }
  }
  
  // 便捷的翻译列表方法
  List<String> translateList(List<String> keys) {
    return keys.map((key) => translate(key)).toList();
  }
  
  // 支持的语言列表
  static final List<Locale> supportedLocales = [
    const Locale('zh', 'CN'), // 中文（中国）
    const Locale('en', 'US'), // 英文（美国）
    const Locale('ja', 'JP'), // 日文（日本）
    const Locale('ko', 'KR'), // 韩文（韩国）
    const Locale('fr', 'FR'), // 法文（法国）
    const Locale('de', 'DE'), // 德文（德国）
    const Locale('es', 'ES'), // 西班牙文（西班牙）
    const Locale('ru', 'RU'), // 俄文（俄罗斯）
    const Locale('ar', 'SA'), // 阿拉伯文（沙特阿拉伯）
  ];
  
  // 获取语言名称
  static String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'es':
        return 'Español';
      case 'ru':
        return 'Русский';
      case 'ar':
        return 'العربية';
      default:
        return 'Unknown';
    }
  }

  // 静态方法，从context获取AppLocalizations实例
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  // 静态工厂方法，用于初始化
  static Future<AppLocalizations> create(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.loadTranslations();
    return localizations;
  }
}

// 代理类，用于加载本地化文件
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .map((e) => e.languageCode)
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return await AppLocalizations.create(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

// 扩展字符串，方便访问翻译
extension StringLocalization on String {
  String tr(BuildContext context, {Map<String, String>? args}) {
    return AppLocalizations.of(context).translate(this, args: args);
  }
}
