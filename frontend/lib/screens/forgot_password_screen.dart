import 'package:flutter/material.dart';
import 'dart:async';
import '../localization/app_localizations.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isCodeSent = false;
  bool _isVerified = false;
  String? _errorMsg;
  int _step = 1; // 1: 输入账号, 2: 验证码验证, 3: 重置密码
  int _countdown = 0;
  Timer? _timer;
  
  @override
  void dispose() {
    _accountController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }
  
  Future<void> _sendVerificationCode() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    
    try {
      // 在实际应用中，这里应该调用API发送验证码
      // await AuthService.sendResetCode(_accountController.text);
      
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isCodeSent = true;
        _countdown = 60;
        _step = 2;
      });
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            timer.cancel();
          }
        });
      });
      
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    
    try {
      // 在实际应用中，这里应该调用API验证验证码
      // await AuthService.verifyResetCode(_accountController.text, _codeController.text);
      
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isVerified = true;
        _step = 3;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    
    try {
      // 在实际应用中，这里应该调用API重置密码
      // await AuthService.resetPassword(
      //   _accountController.text,
      //   _codeController.text,
      //   _passwordController.text
      // );
      
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 显示成功消息，然后导航回登录页面
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('password_reset_success'.tr(context)),
            backgroundColor: Colors.green,
          ),
        );
        
        // 短暂延迟后跳转回登录页面
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('forgot_password_title'.tr(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 步骤指示器
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  children: [
                    _buildStepCircle(1, _step >= 1),
                    _buildStepLine(_step >= 2),
                    _buildStepCircle(2, _step >= 2),
                    _buildStepLine(_step >= 3),
                    _buildStepCircle(3, _step >= 3),
                  ],
                ),
              ),
              
              // 错误信息
              if (_errorMsg != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              
              // 步骤1: 输入账号
              if (_step == 1)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'forgot_password_instruction'.tr(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _accountController,
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
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendVerificationCode,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('send_verification_code'.tr(context)),
                    ),
                  ],
                ),
              
              // 步骤2: 验证码验证
              if (_step == 2)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'verification_code_sent'.tr(context, args: {'account': _accountController.text}),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'verification_code'.tr(context),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.security),
                        suffixIcon: _countdown > 0
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text('${_countdown}s'),
                              )
                            : TextButton(
                                onPressed: _isLoading ? null : _sendVerificationCode,
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
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _verifyCode,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('verify'.tr(context)),
                    ),
                  ],
                ),
              
              // 步骤3: 重置密码
              if (_step == 3)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'reset_password_instruction'.tr(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'new_password'.tr(context),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
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
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'confirm_password'.tr(context),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'please_confirm_password'.tr(context);
                        }
                        if (value != _passwordController.text) {
                          return 'passwords_not_match'.tr(context);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('reset_password'.tr(context)),
                    ),
                  ],
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
