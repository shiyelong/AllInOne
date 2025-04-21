import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';

/// 第三方登录组件
class ThirdPartyLogin extends StatelessWidget {
  final List<Map<String, dynamic>> platforms;
  final Function(String) onLoginPressed;

  const ThirdPartyLogin({
    Key? key,
    required this.platforms,
    required this.onLoginPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              const Expanded(child: Divider(color: Colors.white70)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'other_login_methods'.tr(context), 
                  style: const TextStyle(color: Colors.white70)
                ),
              ),
              const Expanded(child: Divider(color: Colors.white70)),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: platforms.map((platform) {
            return Tooltip(
              message: _getLocalizedPlatformName(context, platform['name']),
              child: InkWell(
                onTap: () => onLoginPressed(platform['name']),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _getIconForPlatform(platform['name']),
                      color: platform['color'],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  // 获取平台图标
  IconData _getIconForPlatform(String platform) {
    switch (platform) {
      case '微信':
        return Icons.wechat;
      case 'QQ':
        return Icons.chat;
      case '微博':
        return Icons.web;
      case 'GitHub':
        return Icons.code;
      case 'Google':
        return Icons.g_mobiledata;
      default:
        return Icons.login;
    }
  }
  
  // 获取本地化的平台名称
  String _getLocalizedPlatformName(BuildContext context, String platform) {
    switch (platform) {
      case '微信':
        return 'wechat'.tr(context);
      case 'QQ':
        return 'qq'.tr(context);
      case '微博':
        return 'weibo'.tr(context);
      case 'GitHub':
        return 'github'.tr(context);
      case 'Google':
        return 'google'.tr(context);
      default:
        return platform;
    }
  }
}
