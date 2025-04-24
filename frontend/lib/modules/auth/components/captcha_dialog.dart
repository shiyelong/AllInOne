import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

/// 验证码对话框组件
class CaptchaDialog extends StatefulWidget {
  final String captchaImage;
  final TextEditingController captchaController;
  final Function() onRefresh;
  final Function() onSubmit;

  const CaptchaDialog({
    Key? key,
    required this.captchaImage,
    required this.captchaController,
    required this.onRefresh,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<CaptchaDialog> createState() => _CaptchaDialogState();
}

class _CaptchaDialogState extends State<CaptchaDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.security, color: Colors.blue),
          SizedBox(width: 8),
          Text('人机验证'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '为保证您的账号安全，请完成以下验证',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _buildCaptchaImage(),
          const SizedBox(height: 20),
          TextField(
            controller: widget.captchaController,
            decoration: const InputDecoration(
              labelText: '请输入验证码',
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintText: '不区分大小写',
              prefixIcon: Icon(Icons.verified_user),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(6),
            ],
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: widget.captchaController.text.isEmpty ? null : () {
            Navigator.pop(context);
            widget.onSubmit();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.blue.withOpacity(0.3),
          ),
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _buildCaptchaImage() {
    if (widget.captchaImage.isNotEmpty) {
      return GestureDetector(
        onTap: widget.onRefresh,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.memory(
                base64Decode(widget.captchaImage),
                height: 60,
                fit: BoxFit.fitWidth,
              ),
              Positioned(
                right: 5,
                top: 5,
                child: Icon(
                  Icons.refresh,
                  size: 20,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 10),
            Text('加载验证码...'),
          ],
        ),
      );
    }
  }
}