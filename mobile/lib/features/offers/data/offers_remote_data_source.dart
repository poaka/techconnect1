import 'package:dio/dio.dart';

class OffersRemoteDataSource {
  final Dio _client;

  OffersRemoteDataSource(this._client);

  Future<List<dynamic>> getOffers() async {
    final response = await _client.get('/technician/offers');
    return response.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> acceptOffer(String id) async {
    final response = await _client.post('/offers/$id/accept');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rejectOffer(String id) async {
    final response = await _client.post('/offers/$id/reject');
    return response.data['data'] as Map<String, dynamic>;
  }
}
