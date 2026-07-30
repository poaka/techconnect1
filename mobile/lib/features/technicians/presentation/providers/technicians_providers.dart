import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../data/technicians_remote_data_source.dart';
import '../../data/technicians_repository_impl.dart';
import '../../domain/category.dart';
import '../../domain/city.dart';
import '../../domain/region.dart';
import '../../domain/technician_filter.dart';
import '../../domain/technician_profile.dart';
import '../../domain/technicians_repository.dart';

final Provider<TechniciansRepository> techniciansRepositoryProvider = Provider<TechniciansRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return TechniciansRepositoryImpl(TechniciansRemoteDataSource(client));
});

final FutureProvider<List<Category>> categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(techniciansRepositoryProvider);
  return await repo.getCategories();
});

final FutureProvider<List<City>> citiesProvider = FutureProvider<List<City>>((ref) async {
  final repo = ref.watch(techniciansRepositoryProvider);
  return await repo.getCities();
});

final FutureProvider<List<Region>> regionsProvider = FutureProvider<List<Region>>((ref) async {
  final repo = ref.watch(techniciansRepositoryProvider);
  return await repo.getRegions();
});

class FilterNotifier extends StateNotifier<TechnicianFilter> {
  FilterNotifier() : super(const TechnicianFilter());

  void setQuery(String? q) {
    state = state.copyWith(q: q, page: 1);
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(categoryId: categoryId, page: 1);
  }

  void setCity(String? cityId) {
    state = state.copyWith(cityId: cityId, page: 1);
  }

  void setRegion(String? regionId) {
    state = state.copyWith(regionId: regionId, page: 1);
  }

  void setAvailability(String? status) {
    state = state.copyWith(availabilityStatus: status, page: 1);
  }

  void setMinRating(double? rating) {
    state = state.copyWith(minRating: rating, page: 1);
  }

  void resetFilters() {
    state = const TechnicianFilter();
  }
}

final StateNotifierProvider<FilterNotifier, TechnicianFilter> technicianFilterProvider =
    StateNotifierProvider<FilterNotifier, TechnicianFilter>((ref) => FilterNotifier());

class TechnicianListState {
  final List<TechnicianProfile> items;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;

  const TechnicianListState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
  });

  TechnicianListState copyWith({
    List<TechnicianProfile>? items,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TechnicianListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TechnicianListNotifier extends StateNotifier<TechnicianListState> {
  final TechniciansRepository _repository;
  TechnicianFilter _currentFilter = const TechnicianFilter();

  TechnicianListNotifier(this._repository) : super(const TechnicianListState());

  Future<void> fetchTechnicians({TechnicianFilter? filter, bool isRefresh = false}) async {
    final activeFilter = filter ?? _currentFilter;
    _currentFilter = activeFilter;

    if (isRefresh) {
      state = state.copyWith(isLoading: true, items: [], hasMore: true, clearError: true);
    } else if (state.isLoading) {
      return;
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final results = await _repository.getTechnicians(activeFilter);
      final newItems = isRefresh ? results : [...state.items, ...results];
      state = state.copyWith(
        items: newItems,
        isLoading: false,
        hasMore: results.length >= activeFilter.limit,
      );
    } on Failure catch (failure) {
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Impossible de charger la liste des techniciens');
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    final nextPage = _currentFilter.page + 1;
    _currentFilter = _currentFilter.copyWith(page: nextPage);
    await fetchTechnicians(filter: _currentFilter, isRefresh: false);
  }
}

final StateNotifierProvider<TechnicianListNotifier, TechnicianListState> technicianListNotifierProvider =
    StateNotifierProvider<TechnicianListNotifier, TechnicianListState>((ref) {
  final repo = ref.watch(techniciansRepositoryProvider);
  return TechnicianListNotifier(repo);
});

final FutureProviderFamily<TechnicianProfile, String> technicianDetailProvider =
    FutureProviderFamily<TechnicianProfile, String>((ref, id) async {
  final repo = ref.watch(techniciansRepositoryProvider);
  return await repo.getTechnicianById(id);
});

class UpdateProfileNotifier extends StateNotifier<AsyncValue<TechnicianProfile?>> {
  final TechniciansRepository _repository;
  
  UpdateProfileNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<TechnicianProfile?> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.updateProfile(data);
      state = AsyncValue.data(profile);
      return profile;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final updateProfileProvider = StateNotifierProvider<UpdateProfileNotifier, AsyncValue<TechnicianProfile?>>((ref) {
  final repo = ref.watch(techniciansRepositoryProvider);
  return UpdateProfileNotifier(repo);
});
