class User {
  final String id;
  final String username;
  final String? email;
  final String? phone;
  final bool is2FAEnabled;
  final List<Device> devices;

  User({
    required this.id,
    required this.username,
    this.email,
    this.phone,
    this.is2FAEnabled = false,
    this.devices = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'],
      is2FAEnabled: json['is2FAEnabled'] ?? false,
      devices: (json['devices'] as List<dynamic>? ?? [])
          .map((d) => Device.fromJson(d))
          .toList(),
    );
  }
}

class Device {
  final String id;
  final String name;
  final String loginTime;

  Device({required this.id, required this.name, required this.loginTime});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      loginTime: json['loginTime'],
    );
  }
}