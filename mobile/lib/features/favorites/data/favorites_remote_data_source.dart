import 'package:dio/dio.dart';

class FavoritesRemoteDataSource {
  final Dio _client;

  FavoritesRemoteDataSource(this._client);

  Future<List<dynamic>> getFavorites() async {
    final response = await _client.get('/favorites');
    return response.data['data'] as List<dynamic>;
  }

  Future<void> addFavorite(String technicianId) async {
    await _client.post('/favorites/$technicianId');
  }

  Future<void> removeFavorite(String technicianId) async {
    await _client.delete('/favorites/$technicianId');
  }
}
