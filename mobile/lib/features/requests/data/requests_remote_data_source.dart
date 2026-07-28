import 'package:dio/dio.dart';

class RequestsRemoteDataSource {
  final Dio _client;

  RequestsRemoteDataSource(this._client);

  Future<List<dynamic>> getRequests() async {
    final response = await _client.get('/requests');
    return response.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getRequestById(String id) async {
    final response = await _client.get('/requests/$id');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createRequest({
    required String technicianId,
    String? categoryId,
    required String description,
    String? address,
  }) async {
    final response = await _client.post(
      '/requests',
      data: {
        'technicianId': technicianId,
        'categoryId': categoryId,
        'description': description,
        'address': address,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateRequestStatus(String id, String status) async {
    final response = await _client.patch(
      '/requests/$id/status',
      data: {'status': status},
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}
