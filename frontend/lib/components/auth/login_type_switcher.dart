import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';

/// 登录类型切换器（用于切换登录和注册）
class AccountTypeSwitcher extends StatelessWidget {
  final String accountType;
  final Function(String) onSwitch;

  const AccountTypeSwitcher({
    Key? key,
    required this.accountType,
    required this.onSwitch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onSwitch('login'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: accountType == 'login' 
                      ? Colors.blue 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    'login'.tr(context),
                    style: TextStyle(
                      color: accountType == 'login' 
                          ? Colors.white 
                          : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onSwitch('register'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: accountType == 'register' 
                      ? Colors.blue 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    'register'.tr(context),
                    style: TextStyle(
                      color: accountType == 'register' 
                          ? Colors.white 
                          : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 登录方式类型按钮（手机号、账号、邮箱）
class LoginMethodButton extends StatelessWidget {
  final String type;
  final String text;
  final String currentType;
  final Function(String) onPressed;

  const LoginMethodButton({
    Key? key,
    required this.type,
    required this.text,
    required this.currentType,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = currentType == type;
    return GestureDetector(
      onTap: () => onPressed(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white30,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
