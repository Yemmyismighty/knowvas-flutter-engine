import 'package:equatable/equatable.dart';
import 'user_preferences.dart';
import 'reading_stats.dart';

/// User domain model
class User extends Equatable {
  final String id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String? profilePicture;
  final String? bio;
  final String? preferredCurrency;
  final String? dateOfBirth;
  final String? gender;
  final String? city;
  final String? country;
  final UserPreferences preferences;
  final ReadingStats stats;
  final int followerCount;
  final int followingCount;

  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
    this.bio,
    this.preferredCurrency,
    this.dateOfBirth,
    this.gender,
    this.city,
    this.country,
    required this.preferences,
    required this.stats,
    this.followerCount = 0,
    this.followingCount = 0,
  });

  /// True when the user has completed the welcome/onboarding profile step.
  /// Mirrors the web's check: user.date_of_birth && user.gender
  bool get hasCompletedProfile => dateOfBirth != null && dateOfBirth!.isNotEmpty && gender != null && gender!.isNotEmpty;

  factory User.fromJson(Map<String, dynamic> json) {
    final data = json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : json;
    return User(
      id: data['id']?.toString() ?? '',
      email: data['email'] as String? ?? '',
      username: data['username'] as String? ?? '',
      firstName: data['firstname'] as String? ?? data['first_name'] as String? ?? '',
      lastName: data['lastname'] as String? ?? data['last_name'] as String? ?? '',
      profilePicture: data['profile_picture'] as String?,
      bio: data['bio'] is String ? data['bio'] as String : null,
      preferredCurrency: data['preferred_currency'] as String?,
      dateOfBirth: data['date_of_birth'] as String?,
      gender: data['gender'] as String?,
      city: data['city'] as String?,
      country: data['country'] as String?,
      preferences: data['preferences'] is Map
          ? UserPreferences.fromJson(Map<String, dynamic>.from(data['preferences'] as Map))
          : const UserPreferences(),
      stats: data['stats'] is Map
          ? ReadingStats.fromJson(Map<String, dynamic>.from(data['stats'] as Map))
          : const ReadingStats(),
      followerCount: data['follower_count'] as int? ?? 0,
      followingCount: data['following_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'profile_picture': profilePicture,
      'bio': bio,
      'preferred_currency': preferredCurrency,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'city': city,
      'country': country,
      'preferences': preferences.toJson(),
      'stats': stats.toJson(),
      'follower_count': followerCount,
      'following_count': followingCount,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? profilePicture,
    String? bio,
    String? preferredCurrency,
    String? dateOfBirth,
    String? gender,
    String? city,
    String? country,
    UserPreferences? preferences,
    ReadingStats? stats,
    int? followerCount,
    int? followingCount,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      country: country ?? this.country,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }

  @override
  List<Object?> get props => [
        id, email, username, firstName, lastName, profilePicture, bio,
        preferredCurrency, dateOfBirth, gender, city, country,
        preferences, stats, followerCount, followingCount,
      ];
}
