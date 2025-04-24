import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// 管理用户认证状态的Provider
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  AuthProvider() {
    // 初始化时检查登录状态
    checkAuthState();
  }

  /// 检查当前用户的认证状态
  Future<void> checkAuthState() async {
    _setLoading(true);
    try {
      _isLoggedIn = await AuthService.isLoggedIn();
      if (_isLoggedIn) {
        await getUserData();
      }
    } catch (e) {
      _isLoggedIn = false;
      _userData = null;
    } finally {
      _setLoading(false);
    }
  }

  /// 获取用户数据
  Future<void> getUserData() async {
    if (!_isLoggedIn) return;
    
    _setLoading(true);
    try {
      _userData = await AuthService.getCurrentUser();
    } catch (e) {
      _userData = null;
    } finally {
      _setLoading(false);
    }
  }

  /// 执行登录操作
  Future<bool> login({
    required String type,
    required String account,
    String? code,
    String? password,
  }) async {
    _setLoading(true);
    try {
      final data = await AuthService.login(
        type: type,
        account: account,
        code: code,
        password: password,
      );
      
      _isLoggedIn = true;
      await getUserData();
      return true;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 执行登出操作
  Future<void> logout() async {
    _setLoading(true);
    try {
      await AuthService.logout();
      _isLoggedIn = false;
      _userData = null;
    } finally {
      _setLoading(false);
    }
  }

  // 设置loading状态，避免重复代码
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}