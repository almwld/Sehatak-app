class UserModel {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? userType;
  final bool isVerified;

  UserModel({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.avatar,
    this.userType,
    this.isVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? json['full_name'],
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
      userType: json['role'] ?? 'patient',
    );
  }

  String get displayName => fullName ?? 'مستخدم';
}
