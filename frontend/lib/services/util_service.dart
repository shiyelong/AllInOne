import 'api_service.dart';

/// 通用工具服务
class UtilService {
  /// 获取国家代码列表
  static Future<List<Map<String, dynamic>>> getCountryCodes() async {
    final data = await ApiService.get(
      '/utils/country_codes',
      requireAuth: false,
    );
    
    final List rawList = data['countryCodes'] ?? [];
    return rawList.map((item) => item as Map<String, dynamic>).toList();
  }
  
  /// 获取验证码图片
  static Future<Map<String, dynamic>> getCaptcha() async {
    return await ApiService.get(
      '/auth/captcha',
      requireAuth: false,
    );
  }
  
  /// 验证图形验证码
  static Future<bool> validateCaptcha({
    required String captchaId, 
    required String captchaCode
  }) async {
    await ApiService.post(
      '/auth/validate_captcha',
      body: {
        'captchaId': captchaId,
        'captchaCode': captchaCode,
      },
      requireAuth: false,
    );
    
    return true;
  }
}