import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../../components/auth/third_party_login.dart';
import '../../components/auth/auth_input_fields.dart';
import '../../components/auth/auth_button.dart';
import '../../components/auth/login_type_switcher.dart';
import '../../components/auth/qr_login.dart';
import '../../components/auth/country_code_picker.dart';
import '../../localization/app_localizations.dart';
import '../../providers/locale_provider.dart';
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
              // 标题
              const SizedBox(height: 20), // 减小顶部间距
              ValueListenableBuilder<String>(
                valueListenable: _controller.accountType,
                builder: (context, accountType, _) {
                  return Column(
                    children: [
                      Center(
                        child: Text(
                          accountType == 'login' 
                              ? 'welcome_back'.tr(context)
                              : 'create_account'.tr(context),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          accountType == 'login' 
                              ? 'login_your_account'.tr(context)
                              : 'register_new_account'.tr(context),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              // 登录注册间距
              ValueListenableBuilder<String>(
                valueListenable: _controller.accountType,
                builder: (context, accountType, _) {
                  return SizedBox(height: accountType == 'login' ? 20 : 16); // 减小间距
                },
              ),
              // 登录方式切换（仅登录时显示，注册时不显示）
              ValueListenableBuilder<String>(
                valueListenable: _controller.accountType,
                builder: (context, accountType, _) {
                  return accountType == 'login' 
                      ? AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeInOutCubic,
                          switchOutCurve: Curves.easeInOutCubic,
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, -0.2),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: ValueListenableBuilder<String>(
                            key: ValueKey<String>(_controller.loginType.value),
                            valueListenable: _controller.loginType,
                            builder: (context, loginType, _) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  LoginMethodButton(
                                    type: 'phone',
                                    text: 'phone_login'.tr(context),
                                    currentType: loginType,
                                    onPressed: _controller.switchLoginType,
                                  ),
                                  const SizedBox(width: 12),
                                  LoginMethodButton(
                                    type: 'account',
                                    text: 'account_login'.tr(context),
                                    currentType: loginType,
                                    onPressed: _controller.switchLoginType,
                                  ),
                                ],
                              );
                            },
                          ),
                        )
                      : const SizedBox.shrink(); // 注册时不显示这些按钮
                },
              ),
              // 缩小注册表单的间距
              ValueListenableBuilder<String>(
                valueListenable: _controller.accountType,
                builder: (context, accountType, _) {
                  // 登录和注册表单使用不同的间距
                  final spacing = accountType == 'login' ? 12.0 : 10.0; // 减小间距
                  return SizedBox(height: spacing);
                },
              ),
              // 账号输入
              ValueListenableBuilder<String>(
                valueListenable: _controller.accountType,
                builder: (context, accountType, _) {
                  if (accountType == 'login') {
                    // 登录时，根据登录类型显示不同输入框
                    return ValueListenableBuilder<String>(
                      valueListenable: _controller.loginType,
                      builder: (context, loginType, _) {
                        if (loginType == 'phone') {
                          return ValueListenableBuilder<String>(
                            valueListenable: _controller.countryCode,
                            builder: (context, countryCode, _) {
                              final flagText = _controller.getCountryFlag();
                              return PhoneInputField(
                                controller: _controller.accountController,
                                countryCode: countryCode,
                                countryFlag: Text(flagText, style: const TextStyle(fontSize: 18)),
                                onCountryCodeTap: () => CountryCodePicker.show(
                                  context,
                                  countryCodes: _controller.countryCodes.value,
                                  currentCode: countryCode,
                                  onSelect: (code) => _controller.countryCode.value = code,
                                  isLoading: _controller.isLoadingCountryCodes.value,
                                ),
                              );
                            },
                          );
                        } else if (loginType == 'email') {
                          return EmailInputField(
                            controller: _controller.accountController,
                          );
                        } else {
                          return AccountInputField(
                            controller: _controller.accountController,
                          );
                        }
                      },
                    );
                  } else {
                    // 注册时，显示统一设计的表单
                    return Column(
                      children: [
                        // 手机号输入
                        ValueListenableBuilder<String>(
                          valueListenable: _controller.countryCode,
                          builder: (context, countryCode, _) {
                            final flagText = _controller.getCountryFlag();
                            return PhoneInputField(
                              controller: _controller.phoneController,
                              countryCode: countryCode,
                              countryFlag: Text(flagText, style: const TextStyle(fontSize: 18)),
                              onCountryCodeTap: () => CountryCodePicker.show(
                                context,
                                countryCodes: _controller.countryCodes.value,
                                currentCode: countryCode,
                                onSelect: (code) => _controller.countryCode.value = code,
                                isLoading: _controller.isLoadingCountryCodes.value,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10), // 减小间距
                        
                        // 邮箱输入
                        EmailInputField(
                          controller: _controller.emailController,
                        ),
                      ],
                    );
                  }
                },
              ),
              // 密码输入（仅账号登录和注册时显示）
              ValueListenableBuilder<String>(
                valueListenable: _controller.loginType,
                builder: (context, loginType, _) {
                  return ValueListenableBuilder<String>(
                    valueListenable: _controller.accountType,
                    builder: (context, accountType, _) {
                      // 账号登录和注册都显示密码框，只有手机登录不需要
                      final bool isPhoneLogin = loginType == 'phone' && accountType == 'login';
                      
                      if (!isPhoneLogin) {
                        return AnimatedSlide(
                          offset: Offset(0, isPhoneLogin ? 1 : 0),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          child: AnimatedOpacity(
                            opacity: isPhoneLogin ? 0 : 1,
                            duration: const Duration(milliseconds: 200),
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _controller.obscurePassword,
                              builder: (context, obscurePassword, _) {
                                return Column(
                                  children: [
                                    const SizedBox(height: 12), // 减小间距
                                    PasswordInputField(
                                      controller: _controller.passwordController,
                                      obscureText: obscurePassword,
                                      onToggleVisibility: () => 
                                        _controller.obscurePassword.value = !obscurePassword,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                },
              ),
              const SizedBox(height: 12), // 减小间距
              // 验证码输入 - 仅在手机号登录模式下显示
              ValueListenableBuilder<String>(
                valueListenable: _controller.loginType,
                builder: (context, loginType, _) {
                  return ValueListenableBuilder<String>(
                    valueListenable: _controller.accountType,
                    builder: (context, accountType, _) {
                      // 只有在手机号登录模式下才显示验证码输入框
                      final bool isPhoneLogin = loginType == 'phone' && accountType == 'login';
                      
                      if (isPhoneLogin) {
                        // 手机登录验证码
                        return Padding(
                          padding: const EdgeInsets.only(top: 10.0), // 减小间距
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _controller.isSendingCode,
                            builder: (context, isSending, _) {
                              return ValueListenableBuilder<int>(
                                valueListenable: _controller.countdown,
                                builder: (context, countdown, _) {
                                  return VerificationCodeInputField(
                                    controller: _controller.codeController,
                                    isSending: isSending,
                                    countdown: countdown,
                                    onSendCode: _controller.sendCode,
                                  );
                                },
                              );
                            },
                          ),
                        );
                      } else if (accountType == 'register') {
                        // 注册页面验证码
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0), // 减小间距
                                child: Text(
                                  'verification_codes'.tr(context),
                                  style: const TextStyle(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              
                              // 手机验证码
                              ValueListenableBuilder<bool>(
                                valueListenable: _controller.isSendingPhoneCode,
                                builder: (context, isSending, _) {
                                  return ValueListenableBuilder<int>(
                                    valueListenable: _controller.phoneCodeCountdown,
                                    builder: (context, countdown, _) {
                                      return VerificationCodeInputField(
                                        controller: _controller.phoneCodeController,
                                        isSending: isSending,
                                        countdown: countdown,
                                        onSendCode: () => _controller.sendPhoneCode(),
                                        labelText: 'phone_verification_code'.tr(context),
                                        hintText: 'please_enter_phone_code'.tr(context),
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 8), // 减小间距
                              
                              // 邮箱验证码
                              ValueListenableBuilder<bool>(
                                valueListenable: _controller.isSendingEmailCode,
                                builder: (context, isSending, _) {
                                  return ValueListenableBuilder<int>(
                                    valueListenable: _controller.emailCodeCountdown,
                                    builder: (context, countdown, _) {
                                      return VerificationCodeInputField(
                                        controller: _controller.emailCodeController,
                                        isSending: isSending,
                                        countdown: countdown,
                                        onSendCode: () => _controller.sendEmailCode(),
                                        labelText: 'email_verification_code'.tr(context),
                                        hintText: 'please_enter_email_code'.tr(context),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }
                      
                      // 账号登录模式下不显示验证码输入框
                      return const SizedBox.shrink();
                    },
                  );
                },
              ),
              // 邀请码输入（仅注册时显示）
              ValueListenableBuilder<String>(
                valueListenable: _controller.accountType,
                builder: (context, accountType, _) {
                  if (accountType == 'register') {
                    return Column(
                      children: [
                        TextFormField(
                          controller: _controller.inviteCodeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'invite_code'.tr(context),
                            labelStyle: const TextStyle(color: Colors.white70),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            hintText: 'please_enter_invite_code'.tr(context),
                            hintStyle: const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(Icons.card_giftcard, color: Colors.white70),
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
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'please_enter_invite_code'.tr(context);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10), // 减小间距
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              // 登录/注册切换按钮
              ValueListenableBuilder<String>(
                valueListenable: _controller.accountType,
                builder: (context, accountType, _) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0), // 减小间距
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          accountType == 'login' 
                              ? 'no_account'.tr(context) 
                              : 'already_have_account'.tr(context),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: _controller.switchAccountType,
                          child: Text(
                            accountType == 'login' ? 'register'.tr(context) : 'login'.tr(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              // 登录/注册按钮
              Container(
                margin: const EdgeInsets.only(top: 16.0, bottom: 16.0), // 减小间距
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _controller.submitForm(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: ValueListenableBuilder<String>(
                    valueListenable: _controller.accountType,
                    builder: (context, accountType, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: _controller.isLoading,
                        builder: (context, isLoading, _) {
                          return isLoading 
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                accountType == 'login' ? '登 录' : '注 册',
                                style: const TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white
                                ),
                              );
                        },
                      );
                    },
                  ),
                ),
              ),
              
              // 登录方式分隔线
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'other_login_methods'.tr(context),
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                  ],
                ),
              ),
              
              // 第三方登录
              ThirdPartyLogin(
                platforms: _controller.thirdPartyPlatforms,
                onLoginPressed: _controller.handleThirdPartyLogin,
              ),
              
              // 忘记密码和二维码登录（仅登录页面显示）
              ValueListenableBuilder<String>(
                valueListenable: _controller.accountType,
                builder: (context, accountType, _) {
                  if (accountType == 'login') {
                    return ValueListenableBuilder<String>(
                      valueListenable: _controller.loginType,
                      builder: (context, loginType, _) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/forgot-password');
                                },
                                child: Text(
                                  'forgot_password'.tr(context),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                              const SizedBox(width: 12),
                              TextButton.icon(
                                onPressed: _controller.toggleQrCode,
                                icon: const Icon(
                                  Icons.qr_code_scanner,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                label: Text(
                                  'qr_code_login'.tr(context),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              const SizedBox(height: 16), // 减小间距
            ],
          ),
        ),
      ),
    );
  }
}
