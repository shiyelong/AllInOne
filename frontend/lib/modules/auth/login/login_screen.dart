import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../components/third_party_login.dart';
import '../components/auth_input_fields.dart';
import '../components/auth_button.dart';
import '../../../utils/validators.dart';
import '../components/qr_login.dart';
import '../components/country_code_picker.dart';
import '../../../localization/app_localizations.dart';
import '../../../providers/locale_provider.dart';
import 'login_controller.dart';

/// 登录和注册页面
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late LoginController _controller;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late VideoPlayerController _videoPlayerController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    
    // 初始化登录控制器
    _controller = LoginController(context);
    _controller.animationController = _animationController;
    
    _initVideoPlayer();
  }
  
  void _initVideoPlayer() {
    try {
      _videoPlayerController = VideoPlayerController.asset('assets/videos/background.mp4');
      _videoPlayerController.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoPlayerController.setLooping(true);
          _videoPlayerController.play();
        }
      }).catchError((error) {
        debugPrint('视频初始化错误: $error');
        if (mounted) {
          setState(() {
            _isVideoInitialized = false;
          });
        }
      });
    } catch (e) {
      debugPrint('视频加载错误: $e');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    if (_isVideoInitialized) {
      _videoPlayerController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景视频或渐变色
          _buildBackground(),
          
          // 内容
          SafeArea(
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.showQrCode,
              builder: (context, showQrCode, _) {
                return showQrCode
                    ? _buildQrLoginView()
                    : _buildLoginFormView();
              },
            ),
          ),
          
          // 语言切换按钮
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.language, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(context, '/language-settings');
                },
                tooltip: 'language_settings'.tr(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建背景
  Widget _buildBackground() {
    if (_isVideoInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoPlayerController.value.size.width,
            height: _videoPlayerController.value.size.height,
            child: VideoPlayer(_videoPlayerController),
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
          ),
        ),
      );
    }
  }
  
  // 构建二维码登录视图
  Widget _buildQrLoginView() {
    return ValueListenableBuilder<String>(
      valueListenable: _controller.qrCodeData,
      builder: (context, qrCodeData, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _controller.isQrScanned,
          builder: (context, isQrScanned, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: _controller.isLoading,
              builder: (context, isLoading, _) {
                return ValueListenableBuilder<String?>(
                  valueListenable: _controller.errorMsg,
                  builder: (context, errorMsg, _) {
                    return QrLoginView(
                      isLoading: isLoading,
                      qrCodeData: qrCodeData,
                      isQrScanned: isQrScanned,
                      errorMsg: errorMsg,
                      onGenerateQrCode: _controller.generateQrCode,
                      onToggleQrCode: _controller.toggleQrCode,
                      onThirdPartyLogin: _controller.handleThirdPartyLogin,
                      thirdPartyPlatforms: _controller.thirdPartyPlatforms,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
  
  // 构建登录表单视图
  Widget _buildLoginFormView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'assets/imgs/logo.png',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 20),
              
              // 标题
              ValueListenableBuilder<String>(
                valueListenable: _controller.accountType,
                builder: (context, accountType, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accountType == 'login'
                            ? 'welcome_back'.tr(context)
                            : 'create_account'.tr(context),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        accountType == 'login'
                            ? 'login_your_account'.tr(context)
                            : 'register_new_account'.tr(context),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // 登录类型切换
              ValueListenableBuilder<String>(
                valueListenable: _controller.accountType,
                builder: (context, accountType, _) {
                  return ValueListenableBuilder<String>(
                    valueListenable: _controller.loginType,
                    builder: (context, loginType, _) {
                      return LoginTypeSwitcher(
                        loginType: loginType,
                        onSwitch: _controller.switchLoginType,
                        showAccountType: accountType == 'login',
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              
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
              
              // 输入字段
              ValueListenableBuilder<String>(
                valueListenable: _controller.accountType,
                builder: (context, accountType, _) {
                  return ValueListenableBuilder<String>(
                    valueListenable: _controller.loginType,
                    builder: (context, loginType, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: _controller.obscurePassword,
                        builder: (context, obscurePassword, _) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: _controller.obscureConfirmPassword,
                            builder: (context, obscureConfirmPassword, _) {
                              return ValueListenableBuilder<String>(
                                valueListenable: _controller.countryCode,
                                builder: (context, countryCode, _) {
                                  return ValueListenableBuilder<int>(
                                    valueListenable: _controller.countdown,
                                    builder: (context, countdown, _) {
                                      return ValueListenableBuilder<bool>(
                                        valueListenable: _controller.isSendingCode,
                                        builder: (context, isSendingCode, _) {
                                          return AuthInputFields(
                                            loginType: loginType,
                                            accountType: accountType,
                                            accountController: _controller.accountController,
                                            passwordController: _controller.passwordController,
                                            confirmPasswordController: _controller.confirmPasswordController,
                                            // 暂时注释掉验证码相关参数
                                            // codeController: _controller.codeController,
                                            obscurePassword: obscurePassword,
                                            obscureConfirmPassword: obscureConfirmPassword,
                                            togglePasswordVisibility: _controller.togglePasswordVisibility,
                                            toggleConfirmPasswordVisibility: _controller.toggleConfirmPasswordVisibility,
                                            // 暂时注释掉手机号相关参数
                                            // countryCode: countryCode,
                                            // onSelectCountryCode: () async {
                                            //   final result = await showModalBottomSheet<String>(
                                            //     context: context,
                                            //     backgroundColor: Colors.transparent,
                                            //     isScrollControlled: true,
                                            //     builder: (context) => ValueListenableBuilder<List<Map<String, dynamic>>>(
                                            //       valueListenable: _controller.countryCodes,
                                            //       builder: (context, countryCodes, _) {
                                            //         return ValueListenableBuilder<bool>(
                                            //           valueListenable: _controller.isLoadingCountryCodes,
                                            //           builder: (context, isLoading, _) {
                                            //             return CountryCodePicker(
                                            //               countryCodes: countryCodes,
                                            //               isLoading: isLoading,
                                            //               currentCode: countryCode,
                                            //               onSelect: (code) => Navigator.pop(context, code),
                                            //             );
                                            //           },
                                            //         );
                                            //       },
                                            //     ),
                                            //   );
                                            //   if (result != null) {
                                            //     _controller.countryCode.value = result;
                                            //   }
                                            // },
                                            // 暂时注释掉验证码相关参数
                                            // countdown: countdown,
                                            // isSendingCode: isSendingCode,
                                            // onSendCode: _controller.sendVerificationCode,
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // 登录/注册按钮
              ValueListenableBuilder<String>(
                valueListenable: _controller.accountType,
                builder: (context, accountType, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _controller.isLoading,
                    builder: (context, isLoading, _) {
                      return AnimatedAuthButton(
                        text: accountType == 'login' ? 'login'.tr(context) : 'register'.tr(context),
                        isLoading: isLoading,
                        onPressed: accountType == 'login' ? _controller.handleLogin : _controller.handleRegister,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // 忘记密码 & 二维码登录
              ValueListenableBuilder<String>(
                valueListenable: _controller.accountType,
                builder: (context, accountType, _) {
                  if (accountType == 'login') {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _controller.navigateToForgotPassword,
                          child: Text(
                            'forgot_password'.tr(context),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        TextButton(
                          onPressed: _controller.toggleQrCode,
                          child: Text(
                            'qr_code_login'.tr(context),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // 切换登录/注册
              ValueListenableBuilder<String>(
                valueListenable: _controller.accountType,
                builder: (context, accountType, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        accountType == 'login' ? 'no_account'.tr(context) : 'already_have_account'.tr(context),
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      TextButton(
                        onPressed: () => _controller.switchAccountType(accountType == 'login' ? 'register' : 'login'),
                        child: Text(
                          accountType == 'login' ? 'register'.tr(context) : 'login'.tr(context),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // 第三方登录
              ValueListenableBuilder<String>(
                valueListenable: _controller.accountType,
                builder: (context, accountType, _) {
                  return ThirdPartyLogin(
                    platforms: _controller.thirdPartyPlatforms,
                    onLoginPressed: _controller.handleThirdPartyLogin,
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginTypeSwitcher extends StatelessWidget {
  final String loginType;
  final Function(String) onSwitch;
  final bool showAccountType;

  const LoginTypeSwitcher({
    Key? key,
    required this.loginType,
    required this.onSwitch,
    required this.showAccountType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showAccountType)
          TextButton(
            onPressed: () => onSwitch('email'),
            child: Text(
              '邮箱登录',
              style: TextStyle(
                color: loginType == 'email' ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        // 暂时注释掉手机号登录选项
        /*
        if (showAccountType)
          TextButton(
            onPressed: () => onSwitch('phone'),
            child: Text(
              '手机登录',
              style: TextStyle(
                color: loginType == 'phone' ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        */
        TextButton(
          onPressed: () => onSwitch('qr'),
          child: Text(
            '扫码登录',
            style: TextStyle(
              color: loginType == 'qr' ? Colors.blue : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthInputFields extends StatelessWidget {
  final String loginType;
  final String accountType;
  final TextEditingController accountController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  // 暂时注释掉验证码相关参数
  // final TextEditingController codeController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback togglePasswordVisibility;
  final VoidCallback toggleConfirmPasswordVisibility;
  // 暂时注释掉手机号相关参数
  // final String countryCode;
  // final VoidCallback onSelectCountryCode;
  // final int countdown;
  // final bool isSendingCode;
  // final VoidCallback onSendCode;

  const AuthInputFields({
    Key? key,
    required this.loginType,
    required this.accountType,
    required this.accountController,
    required this.passwordController,
    required this.confirmPasswordController,
    // 暂时注释掉验证码相关参数
    // required this.codeController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.togglePasswordVisibility,
    required this.toggleConfirmPasswordVisibility,
    // 暂时注释掉手机号相关参数
    // required this.countryCode,
    // required this.onSelectCountryCode,
    // required this.countdown,
    // required this.isSendingCode,
    // required this.onSendCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 实现输入字段的布局
    return const Column(
      children: [
        // 根据loginType和accountType显示不同的输入字段
        // 例如手机号/邮箱输入框、密码输入框、验证码输入框等
      ],
    );
  }
}
