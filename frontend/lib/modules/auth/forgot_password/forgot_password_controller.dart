import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

/// 忘记密码控制器 - 处理忘记密码相关的业务逻辑
class ForgotPasswordController {
  final BuildContext context;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  // 控制器
  final TextEditingController accountController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  // 状态
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isCodeSent = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isVerified = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMsg = ValueNotifier<String?>(null);
  final ValueNotifier<int> step = ValueNotifier<int>(1); // 1: 输入账号, 2: 验证码验证, 3: 重置密码
  final ValueNotifier<int> countdown = ValueNotifier<int>(0);
  final ValueNotifier<bool> obscurePassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> obscureConfirmPassword = ValueNotifier<bool>(true);
  
  Timer? timer;
  
  ForgotPasswordController(this.context);
  
  /// 释放资源
  void dispose() {
    accountController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    
    isLoading.dispose();
    isCodeSent.dispose();
    isVerified.dispose();
    errorMsg.dispose();
    step.dispose();
    countdown.dispose();
    obscurePassword.dispose();
    obscureConfirmPassword.dispose();
    
    timer?.cancel();
  }
  
  /// 发送验证码
  Future<void> sendVerificationCode() async {
    if (!formKey.currentState!.validate()) return;
    
    isLoading.value = true;
    errorMsg.value = null;
    
    try {
      // 在实际应用中，这里应该调用API发送验证码
      // await AuthService.sendResetCode(accountController.text);
      
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      isCodeSent.value = true;
      countdown.value = 60;
      step.value = 2;
      
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (countdown.value > 0) {
          countdown.value--;
        } else {
          timer.cancel();
        }
      });
      
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 验证验证码
  Future<void> verifyCode() async {
    if (!formKey.currentState!.validate()) return;
    
    isLoading.value = true;
    errorMsg.value = null;
    
    try {
      // 在实际应用中，这里应该调用API验证验证码
      // await AuthService.verifyResetCode(accountController.text, codeController.text);
      
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      isVerified.value = true;
      step.value = 3;
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 重置密码
  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;
    
    isLoading.value = true;
    errorMsg.value = null;
    
    try {
      // 在实际应用中，这里应该调用API重置密码
      // await AuthService.resetPassword(
      //   accountController.text,
      //   codeController.text,
      //   passwordController.text
      // );
      
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 返回登录页面
      Navigator.of(context).pop(true);
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 重新发送验证码
  Future<void> resendCode() async {
    if (countdown.value > 0) return;
    
    isLoading.value = true;
    errorMsg.value = null;
    
    try {
      // 在实际应用中，这里应该调用API重新发送验证码
      // await AuthService.sendResetCode(accountController.text);
      
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      countdown.value = 60;
      
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (countdown.value > 0) {
          countdown.value--;
        } else {
          timer.cancel();
        }
      });
      
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 切换密码可见性
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }
  
  /// 切换确认密码可见性
  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }
  
  /// 返回上一步
  void goBack() {
    if (step.value > 1) {
      step.value--;
    } else {
      Navigator.of(context).pop();
    }
  }
}