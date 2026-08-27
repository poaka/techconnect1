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
    required String categoryId,
    required String cityId,
    required String description,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _client.post(
      '/requests',
      data: {
        'categoryId': categoryId,
        'cityId': cityId,
        'description': description,
        if (address != null) 'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelRequest(String id) async {
    final response = await _client.post('/requests/$id/cancel');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeRequest(String id) async {
    final response = await _client.post('/requests/$id/complete');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateLocation(String id, double latitude, double longitude) async {
    final response = await _client.post(
      '/requests/$id/location',
      data: {'latitude': latitude, 'longitude': longitude},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getLocation(String id) async {
    try {
      final response = await _client.get('/requests/$id/location');
      return response.data['data'] as Map<String, dynamic>?;
    } catch (e) {
      // Return null if not found (technician hasn't sent location yet)
      return null;
    }
  }
}
