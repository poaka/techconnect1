import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/service_request.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../data/requests_remote_data_source.dart';
import '../../data/requests_repository_impl.dart';
import '../../domain/requests_repository.dart';

final requestsRemoteDataSourceProvider = Provider<RequestsRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return RequestsRemoteDataSource(dioClient.dio);
});

final requestsRepositoryProvider = Provider<RequestsRepository>((ref) {
  final remoteDataSource = ref.watch(requestsRemoteDataSourceProvider);
  return RequestsRepositoryImpl(remoteDataSource);
});

// Provides the list of requests for the current user
final requestListProvider = StateNotifierProvider<RequestListNotifier, AsyncValue<List<ServiceRequest>>>((ref) {
  final repository = ref.watch(requestsRepositoryProvider);
  return RequestListNotifier(repository)..fetchRequests();
});

class RequestListNotifier extends StateNotifier<AsyncValue<List<ServiceRequest>>> {
  final RequestsRepository _repository;

  RequestListNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> fetchRequests() async {
    state = const AsyncValue.loading();
    try {
      final requests = await _repository.getRequests();
      state = AsyncValue.data(requests);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<ServiceRequest> createRequest({
    required String categoryId,
    required String cityId,
    required String description,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final newRequest = await _repository.createRequest(
      categoryId: categoryId,
      cityId: cityId,
      description: description,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
    
    // Add to current list
    if (state.hasValue) {
      state = AsyncValue.data([newRequest, ...state.value!]);
    }
    return newRequest;
  }

  Future<ServiceRequest> cancelRequest(String id) async {
    final updatedRequest = await _repository.cancelRequest(id);
    _updateRequestInState(id, updatedRequest);
    return updatedRequest;
  }

  Future<ServiceRequest> completeRequest(String id) async {
    final updatedRequest = await _repository.completeRequest(id);
    _updateRequestInState(id, updatedRequest);
    return updatedRequest;
  }

  void _updateRequestInState(String id, ServiceRequest updatedRequest) {
    if (state.hasValue) {
      final updatedList = state.value!.map<ServiceRequest>((req) {
        if (req.id == id) {
          return updatedRequest;
        }
        return req;
      }).toList();
      state = AsyncValue.data(updatedList);
    }
  }
}

// Fetches a single request by ID
final requestDetailProvider = FutureProvider.family<ServiceRequest, String>((ref, id) async {
  final repository = ref.watch(requestsRepositoryProvider);
  return repository.getRequestById(id);
});
