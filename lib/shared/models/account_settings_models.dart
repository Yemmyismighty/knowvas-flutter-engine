// Account settings models

class AccountSettings {
  final String firstname;
  final String lastname;
  final String email;
  final String username;
  final String bio;
  final bool publicProfile;
  final bool filterAdultContent;
  final bool readingAnalyticsEnabled;
  final bool socialFeaturesEnabled;

  AccountSettings({
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.username,
    required this.bio,
    required this.publicProfile,
    required this.filterAdultContent,
    required this.readingAnalyticsEnabled,
    required this.socialFeaturesEnabled,
  });

  factory AccountSettings.fromJson(Map<String, dynamic> json) {
    return AccountSettings(
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      bio: json['bio'] ?? '',
      publicProfile: json['publicProfile'] ?? true,
      filterAdultContent: json['filterAdultContent'] ?? false,
      readingAnalyticsEnabled: json['readingAnalyticsEnabled'] ?? true,
      socialFeaturesEnabled: json['socialFeaturesEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'username': username,
      'bio': bio,
      'publicProfile': publicProfile,
      'filterAdultContent': filterAdultContent,
      'readingAnalyticsEnabled': readingAnalyticsEnabled,
      'socialFeaturesEnabled': socialFeaturesEnabled,
    };
  }

  AccountSettings copyWith({
    String? firstname,
    String? lastname,
    String? email,
    String? username,
    String? bio,
    bool? publicProfile,
    bool? filterAdultContent,
    bool? readingAnalyticsEnabled,
    bool? socialFeaturesEnabled,
  }) {
    return AccountSettings(
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      email: email ?? this.email,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      publicProfile: publicProfile ?? this.publicProfile,
      filterAdultContent: filterAdultContent ?? this.filterAdultContent,
      readingAnalyticsEnabled: readingAnalyticsEnabled ?? this.readingAnalyticsEnabled,
      socialFeaturesEnabled: socialFeaturesEnabled ?? this.socialFeaturesEnabled,
    );
  }
}
