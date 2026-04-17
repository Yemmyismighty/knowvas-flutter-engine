import 'package:equatable/equatable.dart';
import 'user.dart';

/// Authentication response model
class AuthResponse extends Equatable {
  final String accessToken;
  final String refreshToken;
  final User user;
  final int expiresIn;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      expiresIn: json['expires_in'] as int? ?? 3600,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user': user.toJson(),
      'expires_in': expiresIn,
    };
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, user, expiresIn];
}

/// Token refresh response model
class TokenResponse extends Equatable {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int? ?? 3600,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
    };
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresIn];
}

/// Sign up data model
class SignUpData extends Equatable {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String username;

  const SignUpData({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.username,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'firstname': firstName,
      'lastname': lastName,
      'username': username,
    };
  }

  @override
  List<Object?> get props => [email, password, firstName, lastName, username];
}
