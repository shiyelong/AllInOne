import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/validators.dart';
import '../../../localization/app_localizations.dart';

/// 手机号输入框组件
class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final String countryCode;
  final Widget countryFlag;
  final VoidCallback onCountryCodeTap;
  final FormFieldValidator<String>? validator;

  const PhoneInputField({
    Key? key,
    required this.controller,
    required this.countryCode,
    required this.countryFlag,
    required this.onCountryCodeTap,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'phone'.tr(context),
        labelStyle: const TextStyle(color: Colors.white70),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: 'please_enter_phone'.tr(context),
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: GestureDetector(
          onTap: onCountryCodeTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.white30, width: 1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                countryFlag,
                const SizedBox(width: 4),
                Text(
                  countryCode,
                  style: const TextStyle(color: Colors.white),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white70),
              ],
            ),
          ),
        ),
        filled: true,
        fillColor: Colors.transparent,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'please_enter_phone'.tr(context);
        }
        final error = Validators.validatePhone(value);
        if (error != null) {
          return error;
        }
        return null;
      },
    );
  }
}

/// 邮箱输入框组件
class EmailInputField extends StatelessWidget {
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  const EmailInputField({
    Key? key,
    required this.controller,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'email'.tr(context),
        labelStyle: const TextStyle(color: Colors.white70),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: 'please_enter_email'.tr(context),
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.email, color: Colors.white70),
        filled: true,
        fillColor: Colors.transparent,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'please_enter_email'.tr(context);
        }
        final error = Validators.validateEmail(value);
        if (error != null) {
          return error;
        }
        return null;
      },
    );
  }
}

/// 账号输入框组件
class AccountInputField extends StatelessWidget {
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  const AccountInputField({
    Key? key,
    required this.controller,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'account_login'.tr(context),
        labelStyle: const TextStyle(color: Colors.white70),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: 'please_enter_account'.tr(context),
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.person, color: Colors.white70),
        filled: true,
        fillColor: Colors.transparent,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'please_enter_account'.tr(context);
        }
        return null;
      },
    );
  }
}

/// 密码输入框组件
class PasswordInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final String labelText;
  final String hintText;
  final VoidCallback onToggleVisibility;
  final FormFieldValidator<String>? validator;

  const PasswordInputField({
    Key? key,
    required this.controller,
    required this.obscureText,
    this.labelText = 'password',
    this.hintText = 'please_enter_password',
    required this.onToggleVisibility,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText.tr(context),
        labelStyle: const TextStyle(color: Colors.white70),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: hintText.tr(context),
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.lock, color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: Colors.transparent,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'please_enter_password'.tr(context);
        }
        if (value.length < 6) {
          return 'password_length_error'.tr(context);
        }
        return null;
      },
    );
  }
}

/// 验证码输入框组件
class VerificationCodeInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final int countdown;
  final VoidCallback onSendCode;
  final String? labelText;
  final String? hintText;

  const VerificationCodeInputField({
    Key? key,
    required this.controller,
    required this.isSending,
    required this.countdown,
    required this.onSendCode,
    this.labelText,
    this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: labelText ?? 'verification_code'.tr(context),
              labelStyle: const TextStyle(color: Colors.white70),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              hintText: hintText ?? 'please_enter_verification_code'.tr(context),
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.security, color: Colors.white70),
              filled: true,
              fillColor: Colors.transparent,
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white30),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'please_enter_verification_code'.tr(context);
              }
              if (value.length < 4) {
                return 'verification_code_length_error'.tr(context);
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 56, // 与输入框高度一致
          alignment: Alignment.center,
          child: ElevatedButton(
            onPressed: countdown > 0 || isSending ? null : onSendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.blue.withOpacity(0.3),
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              minimumSize: const Size(115, 55), // 固定大小
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              countdown > 0 ? '${countdown}s' : 'get_verification_code'.tr(context),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

/// 认证输入字段组件
class AuthInputFields extends StatelessWidget {
  final String loginType;
  final String accountType;
  final TextEditingController accountController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback togglePasswordVisibility;
  final VoidCallback toggleConfirmPasswordVisibility;
  // 暂时注释掉验证码相关参数
  // final TextEditingController codeController;
  // final int countdown;
  // final bool isSendingCode;
  // final VoidCallback onSendCode;
  // 暂时注释掉手机号相关参数
  // final String countryCode;
  // final VoidCallback onSelectCountryCode;

  const AuthInputFields({
    Key? key,
    required this.loginType,
    required this.accountType,
    required this.accountController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.togglePasswordVisibility,
    required this.toggleConfirmPasswordVisibility,
    // 暂时注释掉验证码相关参数
    // required this.codeController,
    // required this.countdown,
    // required this.isSendingCode,
    // required this.onSendCode,
    // 暂时注释掉手机号相关参数
    // required this.countryCode,
    // required this.onSelectCountryCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 账号输入框
        if (loginType == 'email')
          EmailInputField(controller: accountController),
        if (loginType == 'account')
          AccountInputField(controller: accountController),
        const SizedBox(height: 16),

        // 密码输入框
        PasswordInputField(
          controller: passwordController,
          obscureText: obscurePassword,
          onToggleVisibility: togglePasswordVisibility,
        ),
        const SizedBox(height: 16),

        // 确认密码输入框（仅注册时显示）
        if (accountType == 'register')
          PasswordInputField(
            controller: confirmPasswordController,
            obscureText: obscureConfirmPassword,
            labelText: 'confirm_password',
            hintText: 'please_confirm_password',
            onToggleVisibility: toggleConfirmPasswordVisibility,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'please_confirm_password'.tr(context);
              }
              if (value != passwordController.text) {
                return 'password_not_match'.tr(context);
              }
              return null;
            },
          ),
        if (accountType == 'register') const SizedBox(height: 16),
      ],
    );
  }
}