import '../../../core/network/error_mapper.dart';
import '../../technicians/domain/technician_profile.dart';
import '../domain/favorites_repository.dart';
import 'favorites_remote_data_source.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesRemoteDataSource _remoteDataSource;

  FavoritesRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<TechnicianProfile>> getFavorites() async {
    try {
      final res = await _remoteDataSource.getFavorites();
      // The backend returns an array of favorite objects which should contain the technician profile inside.
      // E.g., { id, client_id, technician_id, technician_profile: {...} } or similar.
      // Let's assume the API returns an array of objects where each object has a 'technician' or 'technician_profile' field.
      // If the backend returns a flat array of profiles, we can parse directly.
      // Let's parse assuming the backend returns the favorites containing the profile in 'technician_profile' or flattened.
      return res.map((e) {
        final profileData = e['technician'] ?? e;
        return TechnicianProfile.fromJson(profileData as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> addFavorite(String technicianId) async {
    try {
      await _remoteDataSource.addFavorite(technicianId);
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> removeFavorite(String technicianId) async {
    try {
      await _remoteDataSource.removeFavorite(technicianId);
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }
}
