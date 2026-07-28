import '../../technicians/domain/technician_profile.dart';

abstract class FavoritesRepository {
  Future<List<TechnicianProfile>> getFavorites();
  Future<void> addFavorite(String technicianId);
  Future<void> removeFavorite(String technicianId);
}
