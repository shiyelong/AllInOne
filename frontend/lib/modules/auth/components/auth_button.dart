import 'package:flutter/material.dart';
import '../../../localization/app_localizations.dart';

/// 登录/注册动画按钮组件
class AnimatedAuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const AnimatedAuthButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              text.tr(context),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}