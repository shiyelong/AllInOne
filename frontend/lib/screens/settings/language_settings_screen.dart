import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/app_localizations.dart';
import '../../providers/locale_provider.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('language_settings'.tr(context)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: Colors.grey[900], 
        child: Column(
          children: [
            // 跟随系统语言选项
            Consumer<LocaleProvider>(
              builder: (context, provider, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: SwitchListTile(
                    title: Text(
                      'follow_system_language'.tr(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'follow_system_language_desc'.tr(context),
                      style: TextStyle(
                        color: Colors.grey[300],
                      ),
                    ),
                    value: provider.followSystem,
                    onChanged: (value) {
                      // 如果切换到不跟随系统，并且没有设置过语言，选择默认语言
                      if (!value && provider.locale == null) {
                        // 默认选择中文
                        provider.setLocale(const Locale('zh', 'CN'));
                      }
                      provider.setFollowSystem(value);
                    },
                    activeColor: Colors.blue,
                    inactiveTrackColor: Colors.grey[700],
                  ),
                );
              },
            ),
            const Divider(
              color: Colors.grey,
              thickness: 0.5,
            ),
            
            // 如果不跟随系统，显示语言选择列表
            Consumer<LocaleProvider>(
              builder: (context, provider, child) {
                if (provider.followSystem) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'current_system_language'.tr(context) + 
                              AppLocalizations.getLanguageName(AppLocalizations.getDeviceLocale()),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // 确保有一个默认选项
                if (provider.locale == null) {
                  // 如果关闭跟随系统但没有选择语言，自动选择中文
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    provider.setLocale(const Locale('zh', 'CN'));
                  });
                }
                
                return Expanded(
                  child: ListView.builder(
                    itemCount: AppLocalizations.supportedLocales.length,
                    itemBuilder: (context, index) {
                      final locale = AppLocalizations.supportedLocales[index];
                      final languageName = AppLocalizations.getLanguageName(locale);
                      final bool isSelected = provider.locale?.languageCode == locale.languageCode &&
                                             provider.locale?.countryCode == locale.countryCode;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RadioListTile<Locale>(
                          title: Text(
                            languageName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${locale.languageCode}-${locale.countryCode}',
                            style: TextStyle(
                              color: Colors.grey[400],
                            ),
                          ),
                          value: locale,
                          groupValue: provider.locale,
                          onChanged: (Locale? value) {
                            if (value != null) {
                              provider.setLocale(value);
                            }
                          },
                          activeColor: Colors.blue,
                          selected: isSelected,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
