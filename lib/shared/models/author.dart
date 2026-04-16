import 'package:equatable/equatable.dart';

/// Author model
class Author extends Equatable {
  final int id;
  final String name;
  final String? bio;
  final String? avatar;
  final String? coverImage;
  final Map<String, String> socialLinks;
  final int followerCount;
  final int publishedWorksCount;
  final bool isFollowedByCurrentUser;

  const Author({
    required this.id,
    required this.name,
    this.bio,
    this.avatar,
    this.coverImage,
    this.socialLinks = const {},
    this.followerCount = 0,
    this.publishedWorksCount = 0,
    this.isFollowedByCurrentUser = false,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] as int,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      avatar: json['avatar'] as String?,
      coverImage: json['cover_image'] as String?,
      socialLinks: (json['social_links'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          {},
      followerCount: json['follower_count'] as int? ?? 0,
      publishedWorksCount: json['published_works_count'] as int? ?? 0,
      isFollowedByCurrentUser: json['is_followed_by_current_user'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'avatar': avatar,
      'cover_image': coverImage,
      'social_links': socialLinks,
      'follower_count': followerCount,
      'published_works_count': publishedWorksCount,
      'is_followed_by_current_user': isFollowedByCurrentUser,
    };
  }

  Author copyWith({
    int? id,
    String? name,
    String? bio,
    String? avatar,
    String? coverImage,
    Map<String, String>? socialLinks,
    int? followerCount,
    int? publishedWorksCount,
    bool? isFollowedByCurrentUser,
  }) {
    return Author(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatar: avatar ?? this.avatar,
      coverImage: coverImage ?? this.coverImage,
      socialLinks: socialLinks ?? this.socialLinks,
      followerCount: followerCount ?? this.followerCount,
      publishedWorksCount: publishedWorksCount ?? this.publishedWorksCount,
      isFollowedByCurrentUser: isFollowedByCurrentUser ?? this.isFollowedByCurrentUser,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        bio,
        avatar,
        coverImage,
        socialLinks,
        followerCount,
        publishedWorksCount,
        isFollowedByCurrentUser,
      ];
}
