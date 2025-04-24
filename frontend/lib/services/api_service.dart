import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 基础API服务，用于处理所有HTTP请求
class ApiService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  /// 获取基础URL
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080'; // Web平台使用localhost
    } else {
      return 'http://127.0.0.1:8080'; // 非Web平台统一使用127.0.0.1
    }
  }

  /// 获取存储的令牌
  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
  
  /// 保存令牌
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }
  
  /// 删除令牌
  static Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }
  
  /// 构建带有认证头的HTTP头
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  /// 执行GET请求
  static Future<Map<String, dynamic>> get(String endpoint, {bool requireAuth = true}) async {
    if (requireAuth) {
      final token = await getToken();
      if (token == null) throw '未登录';
    }
    
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    
    return _handleResponse(response);
  }
  
  /// 执行POST请求
  static Future<Map<String, dynamic>> post(
    String endpoint, 
    {Map<String, dynamic>? body, bool requireAuth = true}
  ) async {
    if (requireAuth) {
      final token = await getToken();
      if (token == null) throw '未登录';
    }
    
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    
    return _handleResponse(response);
  }
  
  /// 执行PUT请求
  static Future<Map<String, dynamic>> put(
    String endpoint, 
    {Map<String, dynamic>? body, bool requireAuth = true}
  ) async {
    if (requireAuth) {
      final token = await getToken();
      if (token == null) throw '未登录';
    }
    
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    
    return _handleResponse(response);
  }
  
  /// 执行DELETE请求
  static Future<Map<String, dynamic>> delete(
    String endpoint, 
    {bool requireAuth = true}
  ) async {
    if (requireAuth) {
      final token = await getToken();
      if (token == null) throw '未登录';
    }
    
    final headers = await _getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    
    return _handleResponse(response);
  }
  
  /// 处理HTTP响应
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      final error = body['error'] ?? '请求失败，请稍后重试';
      throw error;
    }
  }
}