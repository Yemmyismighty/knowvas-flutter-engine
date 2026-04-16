import 'package:equatable/equatable.dart';

/// Review model for content reviews
class Review extends Equatable {
  final int id;
  final String username;
  final String? profilePicture;
  final int rating;
  final String reviewText;
  final String createdAt;
  final int likes;
  final int dislikes;
  final bool? userLikeStatus; // true = liked, false = disliked, null = no action

  const Review({
    required this.id,
    required this.username,
    this.profilePicture,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
    required this.likes,
    required this.dislikes,
    this.userLikeStatus,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    
    return Review(
      id: json['id'] as int,
      username: user?['username'] as String? ?? 'Anonymous',
      profilePicture: user?['profile_picture'] as String?,
      rating: json['rating'] as int,
      reviewText: json['review_text'] as String? ?? json['text'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String? ?? '',
      likes: json['likes'] as int? ?? 0,
      dislikes: json['dislikes'] as int? ?? 0,
      userLikeStatus: json['user_like_status'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': {
        'username': username,
        'profile_picture': profilePicture,
      },
      'rating': rating,
      'review_text': reviewText,
      'created_at': createdAt,
      'likes': likes,
      'dislikes': dislikes,
      'user_like_status': userLikeStatus,
    };
  }

  Review copyWith({
    int? id,
    String? username,
    String? profilePicture,
    int? rating,
    String? reviewText,
    String? createdAt,
    int? likes,
    int? dislikes,
    bool? userLikeStatus,
  }) {
    return Review(
      id: id ?? this.id,
      username: username ?? this.username,
      profilePicture: profilePicture ?? this.profilePicture,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      userLikeStatus: userLikeStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        profilePicture,
        rating,
        reviewText,
        createdAt,
        likes,
        dislikes,
        userLikeStatus,
      ];
}
