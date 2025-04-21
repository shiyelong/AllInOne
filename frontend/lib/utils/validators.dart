class Validators {
  // 手机号验证
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入手机号';
    }
    
    final RegExp phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return '请输入有效的手机号';
    }
    
    return null;
  }
  
  // 邮箱验证
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入邮箱';
    }
    
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
    );
    if (!emailRegex.hasMatch(value)) {
      return '请输入有效的邮箱地址';
    }
    
    return null;
  }
  
  // 密码验证
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    
    if (value.length < 6) {
      return '密码长度不能少于6位';
    }
    
    return null;
  }
  
  // 用户名验证
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入用户名';
    }
    
    if (value.length < 4) {
      return '用户名长度不能少于4位';
    }
    
    return null;
  }
  
  // 验证码验证
  static String? validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入验证码';
    }
    
    if (value.length != 6) {
      return '请输入6位验证码';
    }
    
    final RegExp codeRegex = RegExp(r'^\d{6}$');
    if (!codeRegex.hasMatch(value)) {
      return '验证码必须是6位数字';
    }
    
    return null;
  }

  // 通用账号验证
  static String? validateAccount(String? value, String type) {
    switch (type) {
      case 'phone':
        return validatePhone(value);
      case 'email':
        return validateEmail(value);
      case 'username':
        return validateUsername(value);
      default:
        return '未知账号类型';
    }
  }
}