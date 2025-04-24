import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/auth_service.dart';
import '../../../utils/validators.dart';
import '../../../../localization/app_localizations.dart';

/// 登录控制器 - 处理登录相关的业务逻辑
class LoginController {
  final BuildContext context;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  // 控制器
  final TextEditingController accountController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController captchaController = TextEditingController();
  
  // 注册页面专用控制器
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController inviteCodeController = TextEditingController();
  final TextEditingController phoneCodeController = TextEditingController();
  final TextEditingController emailCodeController = TextEditingController();
  
  // 状态
  final ValueNotifier<String> loginType = ValueNotifier<String>('phone');
  final ValueNotifier<String> accountType = ValueNotifier<String>('login');
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMsg = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isSendingCode = ValueNotifier<bool>(false);
  final ValueNotifier<int> countdown = ValueNotifier<int>(0);
  final ValueNotifier<bool> obscurePassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> obscureConfirmPassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> showQrCode = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isQrScanned = ValueNotifier<bool>(false);
  final ValueNotifier<String> qrCodeData = ValueNotifier<String>('');
  final ValueNotifier<String> countryCode = ValueNotifier<String>('+86');
  final ValueNotifier<bool> isRobotVerified = ValueNotifier<bool>(false);
  
  // 注册页面专用状态
  final ValueNotifier<bool> isSendingPhoneCode = ValueNotifier<bool>(false);
  final ValueNotifier<int> phoneCodeCountdown = ValueNotifier<int>(0);
  final ValueNotifier<bool> isSendingEmailCode = ValueNotifier<bool>(false);
  final ValueNotifier<int> emailCodeCountdown = ValueNotifier<int>(0);
  
  // 验证码相关
  String captchaId = '';
  String captchaImage = '';
  Timer? codeTimer;
  Timer? qrCheckTimer;
  
  // 国家区号列表
  final ValueNotifier<List<Map<String, dynamic>>> countryCodes = ValueNotifier<List<Map<String, dynamic>>>([]);
  final ValueNotifier<bool> isLoadingCountryCodes = ValueNotifier<bool>(false);
  
  // 第三方登录平台
  final List<Map<String, dynamic>> thirdPartyPlatforms = [
    {'name': '微信', 'icon': 'assets/icons/wechat.svg', 'color': const Color(0xFF07C160)},
    {'name': 'QQ', 'icon': 'assets/icons/qq.svg', 'color': const Color(0xFF12B7F5)},
    {'name': '微博', 'icon': 'assets/icons/weibo.svg', 'color': const Color(0xFFE6162D)},
    {'name': 'GitHub', 'icon': 'assets/icons/github.svg', 'color': const Color(0xFF24292E)},
    {'name': 'Google', 'icon': 'assets/icons/google.svg', 'color': const Color(0xFF4285F4)},
  ];
  
  /// 动画控制器 - 由调用者提供并管理
  late AnimationController animationController;
  
  LoginController(this.context) {
    // 添加监听器
    accountController.addListener(_updateLoginButtonState);
    passwordController.addListener(_updateLoginButtonState);
    codeController.addListener(_updateLoginButtonState);
    
    // 初始化数据
    _fetchCountryCodes();
    _getCaptcha();
  }
  
  /// 释放资源
  void dispose() {
    accountController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    codeController.dispose();
    captchaController.dispose();
    
    // 注册页面控制器释放
    phoneController.dispose();
    emailController.dispose();
    inviteCodeController.dispose();
    phoneCodeController.dispose();
    emailCodeController.dispose();
    
    codeTimer?.cancel();
    qrCheckTimer?.cancel();
    
    loginType.dispose();
    accountType.dispose();
    isLoading.dispose();
    errorMsg.dispose();
    isSendingCode.dispose();
    countdown.dispose();
    obscurePassword.dispose();
    obscureConfirmPassword.dispose();
    showQrCode.dispose();
    isQrScanned.dispose();
    qrCodeData.dispose();
    countryCode.dispose();
    isRobotVerified.dispose();
    countryCodes.dispose();
    isLoadingCountryCodes.dispose();
    
    // 注册页面状态释放
    isSendingPhoneCode.dispose();
    phoneCodeCountdown.dispose();
    isSendingEmailCode.dispose();
    emailCodeCountdown.dispose();
  }
  
  /// 更新登录按钮状态
  void _updateLoginButtonState() {
    // 根据输入内容判断登录按钮是否可用
    // 实际项目中可以在此实现更复杂的表单验证逻辑
    isLoading.value = false;
  }
  
  /// 获取国家区号列表
  Future<void> _fetchCountryCodes() async {
    isLoadingCountryCodes.value = true;
    
    try {
      final result = await AuthService.getCountryCodes();
      List<Map<String, dynamic>> codes = List<Map<String, dynamic>>.from(result['data'] ?? []);
      
      if (codes.isEmpty) {
        // 如果API返回为空，使用默认值
        codes = [
          {'name': '中国', 'code': '+86', 'flag': '🇨🇳'},
          {'name': '美国', 'code': '+1', 'flag': '🇺🇸'},
          {'name': '英国', 'code': '+44', 'flag': '🇬🇧'},
          {'name': '日本', 'code': '+81', 'flag': '🇯🇵'},
          {'name': '韩国', 'code': '+82', 'flag': '🇰🇷'},
          {'name': '澳大利亚', 'code': '+61', 'flag': '🇦🇺'},
          {'name': '加拿大', 'code': '+1', 'flag': '🇨🇦'},
          {'name': '德国', 'code': '+49', 'flag': '🇩🇪'},
          {'name': '法国', 'code': '+33', 'flag': '🇫🇷'},
          {'name': '俄罗斯', 'code': '+7', 'flag': '🇷🇺'},
        ];
      }
      
      countryCodes.value = codes;
    } catch (e) {
      // 使用默认值
      countryCodes.value = [
        {'name': '中国', 'code': '+86', 'flag': '🇨🇳'},
        {'name': '美国', 'code': '+1', 'flag': '🇺🇸'},
        {'name': '英国', 'code': '+44', 'flag': '🇬🇧'},
        {'name': '日本', 'code': '+81', 'flag': '🇯🇵'},
        {'name': '韩国', 'code': '+82', 'flag': '🇰🇷'},
        {'name': '澳大利亚', 'code': '+61', 'flag': '🇦🇺'},
        {'name': '加拿大', 'code': '+1', 'flag': '🇨🇦'},
        {'name': '德国', 'code': '+49', 'flag': '🇩🇪'},
        {'name': '法国', 'code': '+33', 'flag': '🇫🇷'},
        {'name': '俄罗斯', 'code': '+7', 'flag': '🇷🇺'},
      ];
    } finally {
      isLoadingCountryCodes.value = false;
    }
  }
  
  /// 获取图形验证码
  Future<void> _getCaptcha() async {
    try {
      final result = await AuthService.getCaptcha();
      captchaId = result['captchaId'] ?? '';
      captchaImage = result['captchaImage'] ?? '';
    } catch (e) {
      debugPrint('获取验证码失败: $e');
    }
  }
  
  /// 切换登录类型（手机号、邮箱、账号）
  void switchLoginType(String type) {
    if (loginType.value == type) return;
    
    // 使用动画转换
    final previousType = loginType.value;
    loginType.value = type;
    
    // 切换类型时重置错误信息和输入内容
    errorMsg.value = null;
    
    // 清空计时器
    if (previousType == 'phone') {
      countdown.value = 0;
      codeTimer?.cancel();
    }
  }
  
  /// 切换账号类型（登录、注册）
  void switchAccountType(String type) {
    if (accountType.value == type) return;
    
    // 使用动画转换
    accountType.value = type;
    
    // 切换类型时重置错误信息和输入内容
    errorMsg.value = null;
    accountController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    codeController.clear();
    
    // 清空计时器
    countdown.value = 0;
    codeTimer?.cancel();
  }
  
  /// 切换密码可见性
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }
  
  /// 切换确认密码可见性
  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }
  
  /// 切换二维码登录
  void toggleQrCode() {
    showQrCode.value = !showQrCode.value;
    
    if (showQrCode.value) {
      // 生成二维码
      generateQrCode();
    } else {
      // 取消二维码登录
      qrCheckTimer?.cancel();
      isQrScanned.value = false;
    }
  }
  
  /// 生成二维码
  Future<void> generateQrCode() async {
    isLoading.value = true;
    errorMsg.value = null;
    
    try {
      // 在实际应用中，这里应该调用API获取二维码数据
      // final result = await AuthService.generateQrCode();
      // qrCodeData.value = result['qrCodeData'];
      
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      qrCodeData.value = 'https://example.com/qr/login?token=sample_token_${DateTime.now().millisecondsSinceEpoch}';
      
      // 启动定时器检查二维码状态
      _startQrCodeCheck();
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 开始检查二维码状态
  void _startQrCodeCheck() {
    // 取消之前的定时器
    qrCheckTimer?.cancel();
    
    // 创建新的定时器，每3秒检查一次二维码状态
    qrCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        // 在实际应用中，这里应该调用API检查二维码状态
        // final result = await AuthService.checkQrCodeStatus(qrCodeData.value);
        // final status = result['status'];
        
        // 模拟API调用和随机状态
        await Future.delayed(const Duration(milliseconds: 500));
        final random = DateTime.now().millisecondsSinceEpoch % 10;
        
        // 模拟二维码被扫描的情况（10%的概率）
        if (random == 0 && !isQrScanned.value) {
          isQrScanned.value = true;
        }
        
        // 模拟二维码过期的情况（10%的概率，且已经过了30秒）
        if (random == 1 && timer.tick > 10) {
          timer.cancel();
          errorMsg.value = 'qr_code_expired'.tr(context);
        }
        
        // 模拟登录成功的情况（10%的概率，且已经被扫描）
        if (random == 2 && isQrScanned.value) {
          timer.cancel();
          await _handleLoginSuccess({'token': 'sample_token', 'user': {'id': '1', 'name': 'User'}});
        }
      } catch (e) {
        debugPrint('检查二维码状态失败: $e');
      }
    });
  }
  
  /// 发送验证码
  Future<void> sendVerificationCode() async {
    if (loginType.value == 'phone' && Validators.validatePhone(accountController.text) != null) {
      errorMsg.value = 'invalid_phone'.tr(context);
      return;
    }
    
    if (loginType.value == 'email' && !Validators.isValidEmail(accountController.text)) {
      errorMsg.value = 'invalid_email'.tr(context);
      return;
    }
    
    isSendingCode.value = true;
    errorMsg.value = null;
    
    try {
      // 在实际应用中，这里应该调用API发送验证码
      // await AuthService.sendVerificationCode(
      //   loginType.value,
      //   accountController.text,
      //   captchaId,
      //   captchaController.text
      // );
      
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 开始倒计时
      countdown.value = 60;
      codeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (countdown.value > 0) {
          countdown.value--;
        } else {
          timer.cancel();
        }
      });
      
      // 显示提示信息
      final destination = loginType.value == 'phone' ? 'phone_destination'.tr(context) : 'email_destination'.tr(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('verification_sent'.tr(context).replaceAll('{destination}', destination)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      errorMsg.value = e.toString();
      // 刷新验证码
      _getCaptcha();
    } finally {
      isSendingCode.value = false;
    }
  }
  
  /// 处理登录
  Future<void> handleLogin() async {
    if (!formKey.currentState!.validate()) return;
    
    isLoading.value = true;
    errorMsg.value = null;
    
    try {
      // 在实际应用中，这里应该调用API进行登录
      // final result = await AuthService.login(
      //   loginType.value,
      //   accountController.text,
      //   passwordController.text,
      //   codeController.text
      // );
      
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      final result = {
        'token': 'sample_token',
        'user': {'id': '1', 'name': 'User'}
      };
      
      await _handleLoginSuccess(result);
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 处理注册
  Future<void> handleRegister() async {
    if (!formKey.currentState!.validate()) return;
    
    isLoading.value = true;
    errorMsg.value = null;
    
    try {
      // 在实际应用中，这里应该调用API进行注册
      // final result = await AuthService.register(
      //   loginType.value,
      //   accountController.text,
      //   passwordController.text,
      //   codeController.text,
      //   inviteCodeController.text
      // );
      
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      final result = {
        'token': 'sample_token',
        'user': {'id': '1', 'name': 'User'}
      };
      
      // 显示注册成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('register_success'.tr(context)),
          backgroundColor: Colors.green,
        ),
      );
      
      // 自动登录
      await _handleLoginSuccess(result);
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 处理第三方登录
  Future<void> handleThirdPartyLogin(String platform) async {
    isLoading.value = true;
    errorMsg.value = null;
    
    try {
      // 在实际应用中，这里应该调用API进行第三方登录
      // final result = await AuthService.thirdPartyLogin(platform);
      
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 显示功能开发中的提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('feature_developing'.tr(context).replaceAll('{feature}', platform)),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 处理登录成功
  Future<void> _handleLoginSuccess(Map<String, dynamic> result) async {
    // 保存登录信息
    // await AuthService.saveAuthInfo(result['token'], result['user']);
    
    // 显示登录成功消息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('login_success'.tr(context)),
        backgroundColor: Colors.green,
      ),
    );
    
    // 导航到主页
    Navigator.pushReplacementNamed(context, '/home');
  }
  
  /// 导航到忘记密码页面
  void navigateToForgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }
}