import 'package:flutter/material.dart';
import '../../../localization/app_localizations.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late ForgotPasswordController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = ForgotPasswordController(context);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('forgot_password_title'.tr(context)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _controller.goBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 步骤指示器
              ValueListenableBuilder<int>(
                valueListenable: _controller.step,
                builder: (context, step, _) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Row(
                      children: [
                        _buildStepCircle(1, step >= 1),
                        _buildStepLine(step >= 2),
                        _buildStepCircle(2, step >= 2),
                        _buildStepLine(step >= 3),
                        _buildStepCircle(3, step >= 3),
                      ],
                    ),
                  );
                },
              ),
              
              // 错误信息
              ValueListenableBuilder<String?>(
                valueListenable: _controller.errorMsg,
                builder: (context, errorMsg, _) {
                  if (errorMsg == null) return const SizedBox.shrink();
                  
                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      errorMsg,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                },
              ),
              
              // 步骤1: 输入账号
              ValueListenableBuilder<int>(
                valueListenable: _controller.step,
                builder: (context, step, _) {
                  if (step != 1) return const SizedBox.shrink();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'forgot_password_instruction'.tr(context),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _controller.accountController,
                        decoration: InputDecoration(
                          labelText: 'email_or_phone'.tr(context),
                          hintText: 'forgot_password_account_hint'.tr(context),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.account_circle),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'please_enter_account'.tr(context);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ValueListenableBuilder<bool>(
                        valueListenable: _controller.isLoading,
                        builder: (context, isLoading, _) {
                          return ElevatedButton(
                            onPressed: isLoading ? null : _controller.sendVerificationCode,
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text('send_verification_code'.tr(context)),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              
              // 步骤2: 验证码验证
              ValueListenableBuilder<int>(
                valueListenable: _controller.step,
                builder: (context, step, _) {
                  if (step != 2) return const SizedBox.shrink();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'verification_code_sent'.tr(context, args: {'account': _controller.accountController.text}),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ValueListenableBuilder<int>(
                        valueListenable: _controller.countdown,
                        builder: (context, countdown, _) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: _controller.isLoading,
                            builder: (context, isLoading, _) {
                              return TextFormField(
                                controller: _controller.codeController,
                                decoration: InputDecoration(
                                  labelText: 'verification_code'.tr(context),
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.security),
                                  suffixIcon: countdown > 0
                                      ? Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text('${countdown}s'),
                                        )
                                      : TextButton(
                                          onPressed: isLoading ? null : _controller.resendCode,
                                          child: Text('resend'.tr(context)),
                                        ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'please_enter_verification_code'.tr(context);
                                  }
                                  return null;
                                },
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      ValueListenableBuilder<bool>(
                        valueListenable: _controller.isLoading,
                        builder: (context, isLoading, _) {
                          return ElevatedButton(
                            onPressed: isLoading ? null : _controller.verifyCode,
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text('verify'.tr(context)),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              
              // 步骤3: 重置密码
              ValueListenableBuilder<int>(
                valueListenable: _controller.step,
                builder: (context, step, _) {
                  if (step != 3) return const SizedBox.shrink();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'reset_password_instruction'.tr(context),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ValueListenableBuilder<bool>(
                        valueListenable: _controller.obscurePassword,
                        builder: (context, obscurePassword, _) {
                          return TextFormField(
                            controller: _controller.passwordController,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'new_password'.tr(context),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: _controller.togglePasswordVisibility,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'please_enter_password'.tr(context);
                              }
                              if (value.length < 6) {
                                return 'password_length_error'.tr(context);
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<bool>(
                        valueListenable: _controller.obscureConfirmPassword,
                        builder: (context, obscureConfirmPassword, _) {
                          return TextFormField(
                            controller: _controller.confirmPasswordController,
                            obscureText: obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'confirm_password'.tr(context),
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: _controller.toggleConfirmPasswordVisibility,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'please_confirm_password'.tr(context);
                              }
                              if (value != _controller.passwordController.text) {
                                return 'passwords_not_match'.tr(context);
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      ValueListenableBuilder<bool>(
                        valueListenable: _controller.isLoading,
                        builder: (context, isLoading, _) {
                          return ElevatedButton(
                            onPressed: isLoading ? null : _controller.resetPassword,
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text('reset_password'.tr(context)),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStepCircle(int step, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.blue : Colors.grey.shade300,
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.blue : Colors.grey.shade300,
      ),
    );
  }
}
