import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../localization/app_localizations.dart';

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
    
    // 如果是切换到手机号登录，重置验证码输入
    if (type == 'phone') {
      codeController.clear();
    } else {
      // 如果是切换到其他登录方式，重置密码字段
      passwordController.clear();
      obscurePassword.value = true;
    }
    
    // 清空账号输入字段
    accountController.clear();
  }
  
  /// 切换账号类型（登录、注册）
  void switchAccountType([String? type]) {
    final newType = type ?? (accountType.value == 'login' ? 'register' : 'login');
    
    if (accountType.value == newType) return;
    
    accountType.value = newType;
    errorMsg.value = null;
    accountController.clear();
    passwordController.clear();
    codeController.clear();
    captchaController.clear();
    
    if (newType == 'register') {
      animationController.forward();
      _getCaptcha(); // 获取新的验证码
    } else {
      animationController.reverse();
    }
  }
  
  /// 切换二维码登录/密码登录
  void toggleQrCode() {
    // 保存当前登录类型，以便返回时恢复
    final previousLoginType = loginType.value;
    final previousAccountType = accountType.value;
    
    showQrCode.value = !showQrCode.value;
    errorMsg.value = null;
    
    if (showQrCode.value) {
      // 进入二维码页面，生成二维码
      generateQrCode();
    } else {
      // 从二维码页面返回，恢复之前的登录类型
      loginType.value = previousLoginType;
      accountType.value = previousAccountType;
      qrCheckTimer?.cancel();
    }
  }
  
  /// 生成二维码
  Future<void> generateQrCode() async {
    isLoading.value = true;
    errorMsg.value = null;
    isQrScanned.value = false;
    
    try {
      // 调用API获取二维码数据
      final result = await AuthService.generateQrCode();
      qrCodeData.value = result['qrCodeData'] ?? '';
      
      // 开始轮询检查二维码状态
      if (result.containsKey('sessionId')) {
        _startQrCodeStatusCheck(result['sessionId']);
      }
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 开始检查二维码状态
  void _startQrCodeStatusCheck(String sessionId) {
    // 取消之前的定时器
    qrCheckTimer?.cancel();
    
    // 创建新的定时器，每3秒检查一次
    qrCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final result = await AuthService.checkQrCodeStatus(sessionId);
        
        if (result['status'] == 'scanned') {
          // 二维码已扫描
          isQrScanned.value = true;
        } else if (result['status'] == 'confirmed') {
          // 用户已确认登录
          qrCheckTimer?.cancel();
          
          // 保存token并跳转
          if (result.containsKey('token')) {
            await AuthService.saveToken(result['token']);
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else if (result['status'] == 'expired') {
          // 二维码已过期
          qrCheckTimer?.cancel();
          errorMsg.value = '二维码已过期，请刷新';
          isQrScanned.value = false;
        }
      } catch (e) {
        // 出错时不中断轮询，只记录错误
        debugPrint('检查二维码状态出错: $e');
      }
    });
  }
  
  /// 显示图形验证码弹窗
  void showCaptchaDialog(BuildContext context, Function onSubmit) {
    captchaController.clear();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                  if (captchaImage.isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        await _getCaptcha();
                        setDialogState(() {});
                      },
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
                              base64Decode(captchaImage),
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
                    )
                  else
                    Container(
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
                    ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: captchaController,
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
                  onPressed: captchaController.text.isEmpty ? null : () {
                    Navigator.pop(context);
                    onSubmit();
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
          },
        );
      },
    );
  }
  
  /// 请求发送验证码
  void sendCode() {
    // 这些操作通常在发送验证码前需要进行的验证
    if (accountController.text.isEmpty) {
      errorMsg.value = loginType.value == 'phone' 
          ? 'please_enter_phone'.tr(context)
          : 'please_enter_email'.tr(context);
      return;
    }
    
    // 发送验证码
    _sendVerificationCode();
  }
  
  /// 发送验证码（内部实现）
  Future<void> _sendVerificationCode() async {
    if (isSendingCode.value) return;
    
    isSendingCode.value = true;
    errorMsg.value = null;
    
    try {
      // 模拟 API 调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 开始倒计时
      countdown.value = 60;
      _startCodeCountdown();
      
      // 清除错误消息
      errorMsg.value = null;
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isSendingCode.value = false;
    }
  }
  
  /// 发送手机验证码（注册页面专用）
  Future<void> sendPhoneCode() async {
    if (phoneController.text.isEmpty) {
      errorMsg.value = 'please_enter_phone'.tr(context);
      return;
    }
    
    final phoneError = Validators.validatePhone(phoneController.text);
    if (phoneError != null) {
      errorMsg.value = 'invalid_phone'.tr(context);
      return;
    }
    
    isSendingPhoneCode.value = true;
    errorMsg.value = null;
    
    try {
      // 模拟 API 调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 开始倒计时
      phoneCodeCountdown.value = 60;
      _startPhoneCodeCountdown();
      
      // 清除错误信息
      errorMsg.value = null;
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isSendingPhoneCode.value = false;
    }
  }
  
  /// 发送邮箱验证码（注册页面专用）
  Future<void> sendEmailCode() async {
    if (emailController.text.isEmpty) {
      errorMsg.value = 'please_enter_email'.tr(context);
      return;
    }
    
    final emailError = Validators.validateEmail(emailController.text);
    if (emailError != null) {
      errorMsg.value = 'invalid_email'.tr(context);
      return;
    }
    
    isSendingEmailCode.value = true;
    errorMsg.value = null;
    
    try {
      // 模拟 API 调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 开始倒计时
      emailCodeCountdown.value = 60;
      _startEmailCodeCountdown();
      
      // 清除错误信息
      errorMsg.value = null;
    } catch (e) {
      errorMsg.value = e.toString();
    } finally {
      isSendingEmailCode.value = false;
    }
  }
  
  /// 开始倒计时
  void _startCodeCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value <= 0) {
        timer.cancel();
        return;
      }
      countdown.value--;
    });
  }
  
  /// 手机验证码倒计时
  void _startPhoneCodeCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (phoneCodeCountdown.value <= 0) {
        timer.cancel();
        return;
      }
      phoneCodeCountdown.value--;
    });
  }
  
  /// 邮箱验证码倒计时
  void _startEmailCodeCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (emailCodeCountdown.value <= 0) {
        timer.cancel();
        return;
      }
      emailCodeCountdown.value--;
    });
  }
  
  /// 处理第三方登录
  void handleThirdPartyLogin(String platform) {
    isLoading.value = true;
    errorMsg.value = null;
    
    // 在真实应用中，这里应该调用相应平台的登录SDK
    // 这里只是模拟第三方登录过程
    Future.delayed(const Duration(seconds: 2), () {
      isLoading.value = false;
      
      // 显示未实现提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('feature_developing'.tr(context, args: {'feature': platform})),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }
  
  /// 提交表单（登录或注册）
  void submitForm() {
    // 先验证表单
    if (!formKey.currentState!.validate()) {
      return;
    }
    
    // 设置加载中状态
    isLoading.value = true;
    errorMsg.value = null;
    
    // 根据当前登录类型和账号类型处理
    if (accountType.value == 'login') {
      // 登录流程
      if (loginType.value == 'phone') {
        // 手机号验证码登录
        _loginWithPhoneCode();
      } else {
        // 账号密码登录
        _loginWithPassword();
      }
    } else {
      // 注册流程
      _register();
    }
  }
  
  /// 手机号验证码登录
  Future<void> _loginWithPhoneCode() async {
    // 获取完整的手机号（包含国家代码）
    final phone = countryCode.value + accountController.text;
    final code = codeController.text;
    
    if (code.isEmpty) {
      isLoading.value = false;
      errorMsg.value = '请输入验证码';
      return;
    }
    
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 登录成功后的操作
      isLoading.value = false;
      
      // 显示登录成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('login_success'.tr(context)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // 跳转到首页
      Future.delayed(const Duration(milliseconds: 200), () {
        Navigator.pushReplacementNamed(context, '/home');
      });
    } catch (e) {
      isLoading.value = false;
      errorMsg.value = e.toString();
    }
  }
  
  /// 账号密码登录
  Future<void> _loginWithPassword() async {
    final account = accountController.text;
    final password = passwordController.text;
    
    if (password.isEmpty) {
      isLoading.value = false;
      errorMsg.value = '请输入密码';
      return;
    }
    
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 登录成功后的操作
      isLoading.value = false;
      
      // 显示登录成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('login_success'.tr(context)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // 跳转到首页
      Future.delayed(const Duration(milliseconds: 200), () {
        Navigator.pushReplacementNamed(context, '/home');
      });
    } catch (e) {
      isLoading.value = false;
      errorMsg.value = e.toString();
    }
  }
  
  /// 注册账号
  Future<void> _register() async {
    // 在实际项目中，这里需要获取所有表单数据并进行更完整的验证
    // 为简化示例，这里只做基本验证
    
    try {
      // 模拟API调用
      await Future.delayed(const Duration(seconds: 1));
      
      // 注册成功后的操作
      isLoading.value = false;
      
      // 显示注册成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('register_success'.tr(context)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // 跳转到首页
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushReplacementNamed(context, '/home');
      });
    } catch (e) {
      isLoading.value = false;
      errorMsg.value = e.toString();
    }
  }
  
  /// 获取国家区号对应的国旗
  String getCountryFlag() {
    String flag = "🌐"; // 默认全球图标
    
    for (var country in countryCodes.value) {
      if (country['code'] == countryCode.value) {
        flag = country['flag'] ?? "🌐";
        break;
      }
    }
    
    return flag;
  }
}
