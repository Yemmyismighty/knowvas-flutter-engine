import 'package:dio/dio.dart';
import 'package:knowvas/core/network/api_client.dart';
import 'package:knowvas/shared/models/curated_models.dart';

class CuratedRepository {
  final ApiClient _apiClient;

  CuratedRepository(this._apiClient);

  Future<Map<String, dynamic>> getCuratedContent(
    String endpoint, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/user/curated/$endpoint',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.data['status'] == 'success') {
        final contents = (response.data['data'] as List)
            .map((json) => CuratedContent.fromJson(json))
            .toList();

        return {
          'contents': contents,
          'hasMore': response.data['hasMore'] ?? false,
        };
      }

      throw Exception('Failed to load curated content');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error');
    }
  }
}

