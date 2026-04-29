import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    required super.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      token: token,
    );
  }

  // Nexus returns { token: '...' } on login — user details come from /api/auth/me/ or we parse what's available
  factory UserModel.fromTokenResponse(Map<String, dynamic> json) {
    return UserModel(
      id: 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      token: json['token'] ?? '',
    );
  }
}