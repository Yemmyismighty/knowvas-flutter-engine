import 'package:equatable/equatable.dart';

/// Download request model
class DownloadRequest extends Equatable {
  final int contentId;
  final String quality; // 'standard', 'high', 'ultra'

  const DownloadRequest({
    required this.contentId,
    this.quality = 'standard',
  });

  Map<String, dynamic> toJson() {
    return {
      'content_id': contentId,
      'quality': quality,
    };
  }

  @override
  List<Object?> get props => [contentId, quality];
}

/// Download response model with signed URL
class DownloadResponse extends Equatable {
  final String signedUrl;
  final String fileHash;
  final int fileSize;
  final int expiresIn;

  const DownloadResponse({
    required this.signedUrl,
    required this.fileHash,
    required this.fileSize,
    required this.expiresIn,
  });

  factory DownloadResponse.fromJson(Map<String, dynamic> json) {
    return DownloadResponse(
      signedUrl: json['signed_url'] as String,
      fileHash: json['file_hash'] as String,
      fileSize: json['file_size'] as int,
      expiresIn: json['expires_in'] as int? ?? 3600,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'signed_url': signedUrl,
      'file_hash': fileHash,
      'file_size': fileSize,
      'expires_in': expiresIn,
    };
  }

  @override
  List<Object?> get props => [signedUrl, fileHash, fileSize, expiresIn];
}
