import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../data/favorites_remote_data_source.dart';
import '../../data/favorites_repository_impl.dart';
import '../../domain/favorites_repository.dart';
import '../../../technicians/domain/technician_profile.dart';

final favoritesRemoteDataSourceProvider = Provider<FavoritesRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return FavoritesRemoteDataSource(dioClient.dio);
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final remoteDataSource = ref.watch(favoritesRemoteDataSourceProvider);
  return FavoritesRepositoryImpl(remoteDataSource);
});

final favoriteTechniciansProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<List<TechnicianProfile>>>((ref) {
  final repository = ref.watch(favoritesRepositoryProvider);
  return FavoritesNotifier(repository)..fetchFavorites();
});

class FavoritesNotifier extends StateNotifier<AsyncValue<List<TechnicianProfile>>> {
  final FavoritesRepository _repository;

  FavoritesNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> fetchFavorites() async {
    state = const AsyncValue.loading();
    try {
      final favorites = await _repository.getFavorites();
      state = AsyncValue.data(favorites);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleFavorite(TechnicianProfile technician) async {
    final currentList = state.valueOrNull ?? [];
    final isFavorite = currentList.any((t) => t.id == technician.id);
    
    // Optimistic UI update
    if (isFavorite) {
      state = AsyncValue.data(currentList.where((t) => t.id != technician.id).toList());
    } else {
      state = AsyncValue.data([...currentList, technician]);
    }

    try {
      if (isFavorite) {
        await _repository.removeFavorite(technician.id);
      } else {
        await _repository.addFavorite(technician.id);
      }
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentList);
      // Ideally, we'd also show a snackbar or some error indication here.
      // But we will throw it back to let the caller handle it.
      rethrow;
    }
  }
  
  bool isFavorite(String technicianId) {
    return state.valueOrNull?.any((t) => t.id == technicianId) ?? false;
  }
}
