import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // 简化的基础URL获取方法，只区分Web和非Web平台
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080'; // Web平台使用localhost
    } else {
      return 'http://127.0.0.1:8080'; // 非Web平台统一使用127.0.0.1
    }
  }
  
  static const storage = FlutterSecureStorage();

  // 登录
  static Future<Map<String, dynamic>> login({
    required String type,
    required String account,
    String? code,
    String? password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': type,
        'account': account,
        if (code != null) 'code': code,
        if (password != null) 'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // 保存token
      if (data['token'] != null) {
        await saveToken(data['token']);
      }
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '登录失败，请稍后重试';
    }
  }

  // 保存令牌
  static Future<void> saveToken(String token) async {
    await storage.write(key: 'auth_token', value: token);
  }

  // 注册
  static Future<Map<String, dynamic>> register({
    required String type,
    required String account,
    required String password,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': type,
        'account': account,
        'password': password,
        'code': code,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '注册失败，请稍后重试';
    }
  }

  // 发送验证码
  static Future<void> sendCode(String type, String account) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send_code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': type,
        'account': account,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '发送验证码失败，请稍后重试';
    }
  }

  // 校验验证码
  static Future<bool> verifyCode(String type, String account, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify_code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': type,
        'account': account,
        'code': code,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '验证码校验失败';
    }
  }

  // 生成二维码
  static Future<Map<String, dynamic>> generateQrCode() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/qrcode/generate'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '生成二维码失败';
    }
  }

  // 检查二维码状态
  static Future<Map<String, dynamic>> checkQrCodeStatus(String sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/qrcode/check?sessionId=$sessionId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '检查二维码状态失败';
    }
  }

  // 扫描二维码 (移动端调用)
  static Future<Map<String, dynamic>> scanQrCode(String qrCode) async {
    final token = await storage.read(key: 'auth_token');
    
    final response = await http.post(
      Uri.parse('$baseUrl/auth/qrcode/scan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'qrCode': qrCode,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '扫描二维码失败';
    }
  }

  // 确认二维码登录 (移动端调用)
  static Future<Map<String, dynamic>> confirmQrLogin(String sessionId) async {
    final token = await storage.read(key: 'auth_token');
    
    final response = await http.post(
      Uri.parse('$baseUrl/auth/qrcode/confirm'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'sessionId': sessionId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '确认二维码登录失败';
    }
  }

  // 检查登录状态
  static Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'auth_token');
    return token != null;
  }

  // 退出登录
  static Future<void> logout() async {
    final token = await storage.read(key: 'auth_token');
    if (token != null) {
      try {
        // 通知后端用户退出
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (e) {
        // 即使后端请求失败，也要清除本地令牌
        print('退出登录请求失败: $e');
      }
    }
    await storage.delete(key: 'auth_token');
  }

  // 获取当前用户信息
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw '未登录';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '获取用户信息失败';
    }
  }

  // 更新用户资料
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw '未登录';
    }

    final response = await http.put(
      Uri.parse('$baseUrl/user/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '更新用户信息失败';
    }
  }

  // 更改密码
  static Future<void> changePassword({
    required String oldPassword, 
    required String newPassword,
  }) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw '未登录';
    }

    final response = await http.post(
      Uri.parse('$baseUrl/user/change_password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '修改密码失败';
    }
  }

  // 忘记密码
  static Future<void> forgotPassword({
    required String type,
    required String account,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot_password'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'type': type,
        'account': account,
        'code': code,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '重置密码失败';
    }
  }

  // 启用两步验证
  static Future<Map<String, dynamic>> enable2FA() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw '未登录';
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/2fa/enable'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '启用两步验证失败';
    }
  }

  // 验证两步验证码
  static Future<bool> verify2FA(String code) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw '未登录';
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/2fa/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'code': code,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '验证两步验证码失败';
    }
  }

  // 获取登录历史
  static Future<List<dynamic>> getLoginHistory() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw '未登录';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/auth/login_history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['history'] ?? [];
    } else {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '获取登录历史失败';
    }
  }

  // 获取登录设备列表
  static Future<List<dynamic>> getDevices() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw '未登录';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/auth/devices'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['devices'] ?? [];
    } else {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '获取设备列表失败';
    }
  }

  // 登出设备
  static Future<void> logoutDevice(int deviceId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw '未登录';
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/devices/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'device_id': deviceId,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '登出设备失败';
    }
  }

  // 绑定邮箱
  static Future<void> bindEmail(String email, String code) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw '未登录';
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/bind_email'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'email': email,
        'code': code,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '绑定邮箱失败';
    }
  }

  // 绑定手机号
  static Future<void> bindPhone(String phone, String code) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw '未登录';
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/bind_phone'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'phone': phone,
        'code': code,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw error['error'] ?? '绑定手机号失败';
    }
  }

  static validateCaptcha({required String captchaId, required String captchaCode}) {}

  static getCountryCodes() {}

  static getCaptcha() {}
}