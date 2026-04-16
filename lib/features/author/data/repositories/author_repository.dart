import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:knowvas/core/constants/api_constants.dart';
import 'package:knowvas/shared/models/author_profile_models.dart';
import 'package:knowvas/core/services/storage_service.dart';

class AuthorRepository {
  final StorageService _storageService;

  AuthorRepository(this._storageService);

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get author profile
  Future<AuthorProfile> getAuthorProfile(int authorId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/author/$authorId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AuthorProfile.fromJson(data);
      } else {
        throw Exception('Failed to load author profile');
      }
    } catch (e) {
      throw Exception('Error fetching author profile: $e');
    }
  }

  /// Follow author
  Future<void> followAuthor(int authorId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/follow/author/$authorId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to follow author');
      }
    } catch (e) {
      throw Exception('Error following author: $e');
    }
  }

  /// Unfollow author
  Future<void> unfollowAuthor(int authorId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/follow/author/$authorId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Failed to unfollow author');
      }
    } catch (e) {
      throw Exception('Error unfollowing author: $e');
    }
  }
}

