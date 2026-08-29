import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/service_request.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../technicians/domain/category.dart';
import '../../../technicians/domain/technician_profile.dart';
import '../../../technicians/presentation/providers/technicians_providers.dart';
import '../../data/admin_remote_data_source.dart';
import '../../domain/platform_stats.dart';
import '../../domain/report.dart';
import '../../domain/technician_document.dart';

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return AdminRemoteDataSource(client);
});

final platformStatsProvider = FutureProvider.autoDispose<PlatformStats>((ref) async {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return dataSource.getPlatformStats();
});

final pendingVerificationsProvider = FutureProvider.autoDispose<List<TechnicianDocument>>((ref) async {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return dataSource.getPendingVerifications();
});

final rejectedVerificationsProvider = FutureProvider.autoDispose<List<TechnicianDocument>>((ref) async {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return dataSource.getRejectedVerifications();
});

final adminUsersProvider = FutureProvider.autoDispose.family<List<AppUser>, String?>((ref, role) async {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return dataSource.getUsers(role: role);
});

final adminTechniciansProvider = FutureProvider.autoDispose<List<TechnicianProfile>>((ref) async {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return dataSource.getTechnicians();
});

final adminServiceRequestsProvider = FutureProvider.autoDispose.family<List<ServiceRequest>, String?>((ref, status) async {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return dataSource.getServiceRequests(status: status);
});

final adminCategoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return dataSource.getCategories();
});

final adminReportsProvider = FutureProvider.autoDispose.family<List<Report>, String?>((ref, status) async {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return dataSource.getReports(status: status);
});

class ReportActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminRemoteDataSource _dataSource;
  final Ref _ref;

  ReportActionsNotifier(this._dataSource, this._ref) : super(const AsyncValue.data(null));

  Future<void> resolveReport(String id, String actionTaken) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.resolveReport(id, actionTaken);
      state = const AsyncValue.data(null);
      _ref.invalidate(adminReportsProvider);
    } catch (e, st) {
      debugPrint('[AdminProviders] Error: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }
}

final reportActionsProvider = StateNotifierProvider<ReportActionsNotifier, AsyncValue<void>>((ref) {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return ReportActionsNotifier(dataSource, ref);
});

class CategoryActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminRemoteDataSource _dataSource;
  final Ref _ref;

  CategoryActionsNotifier(this._dataSource, this._ref) : super(const AsyncValue.data(null));

  Future<void> createCategory(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.createCategory(data);
      state = const AsyncValue.data(null);
      _ref.invalidate(adminCategoriesProvider);
    } catch (e, st) {
      debugPrint('[AdminProviders] Error: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.updateCategory(id, data);
      state = const AsyncValue.data(null);
      _ref.invalidate(adminCategoriesProvider);
    } catch (e, st) {
      debugPrint('[AdminProviders] Error: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCategory(String id) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.deleteCategory(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(adminCategoriesProvider);
    } catch (e, st) {
      debugPrint('[AdminProviders] Error: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }
}

final categoryActionsProvider = StateNotifierProvider<CategoryActionsNotifier, AsyncValue<void>>((ref) {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return CategoryActionsNotifier(dataSource, ref);
});

class ReviewDocumentNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminRemoteDataSource _dataSource;
  final Ref _ref;

  ReviewDocumentNotifier(this._dataSource, this._ref) : super(const AsyncValue.data(null));

  Future<void> reviewDocument({
    required String documentId,
    required String status,
    String? rejectionReason,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.reviewDocument(
        documentId: documentId,
        status: status,
        rejectionReason: rejectionReason,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(pendingVerificationsProvider);
      _ref.invalidate(platformStatsProvider);
    } catch (e, st) {
      debugPrint('[AdminProviders] Error: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }
}

final reviewDocumentProvider = StateNotifierProvider<ReviewDocumentNotifier, AsyncValue<void>>((ref) {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return ReviewDocumentNotifier(dataSource, ref);
});

class UserActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminRemoteDataSource _dataSource;
  final Ref _ref;

  UserActionsNotifier(this._dataSource, this._ref) : super(const AsyncValue.data(null));

  Future<void> deleteUser(String id) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.deleteUser(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(adminUsersProvider);
      _ref.invalidate(platformStatsProvider);
    } catch (e, st) {
      debugPrint('[AdminProviders] Error: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }
}

final userActionsProvider = StateNotifierProvider<UserActionsNotifier, AsyncValue<void>>((ref) {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return UserActionsNotifier(dataSource, ref);
});

class RegionActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminRemoteDataSource _dataSource;
  final Ref _ref;

  RegionActionsNotifier(this._dataSource, this._ref) : super(const AsyncValue.data(null));

  Future<void> createRegion(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.createRegion(data);
      state = const AsyncValue.data(null);
      _ref.invalidate(regionsProvider);
    } catch (e, st) {
      debugPrint('[AdminProviders] Error: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateRegion(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.updateRegion(id, data);
      state = const AsyncValue.data(null);
      _ref.invalidate(regionsProvider);
    } catch (e, st) {
      debugPrint('[AdminProviders] Error: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRegion(String id) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.deleteRegion(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(regionsProvider);
    } catch (e, st) {
      debugPrint('[AdminProviders] Error: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }
}

final regionActionsProvider = StateNotifierProvider<RegionActionsNotifier, AsyncValue<void>>((ref) {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return RegionActionsNotifier(dataSource, ref);
});

class CityActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminRemoteDataSource _dataSource;
  final Ref _ref;

  CityActionsNotifier(this._dataSource, this._ref) : super(const AsyncValue.data(null));

  Future<void> createCity(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.createCity(data);
      state = const AsyncValue.data(null);
      _ref.invalidate(citiesProvider);
    } catch (e, st) {
      debugPrint('[AdminProviders] Error: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCity(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.updateCity(id, data);
      state = const AsyncValue.data(null);
      _ref.invalidate(citiesProvider);
    } catch (e, st) {
      debugPrint('[AdminProviders] Error: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCity(String id) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.deleteCity(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(citiesProvider);
    } catch (e, st) {
      debugPrint('[AdminProviders] Error: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }
}

final cityActionsProvider = StateNotifierProvider<CityActionsNotifier, AsyncValue<void>>((ref) {
  final dataSource = ref.watch(adminRemoteDataSourceProvider);
  return CityActionsNotifier(dataSource, ref);
});
