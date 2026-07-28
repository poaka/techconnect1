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
    required String technicianId,
    String? categoryId,
    required String description,
    String? address,
  }) async {
    final newRequest = await _repository.createRequest(
      technicianId: technicianId,
      categoryId: categoryId,
      description: description,
      address: address,
    );
    
    // Add to current list
    if (state.hasValue) {
      state = AsyncValue.data([newRequest, ...state.value!]);
    }
    return newRequest;
  }

  Future<ServiceRequest> updateStatus(String id, RequestStatus newStatus) async {
    final updatedRequest = await _repository.updateRequestStatus(id, newStatus);
    
    // Update in current list
    if (state.hasValue) {
      final updatedList = state.value!.map<ServiceRequest>((req) {
        if (req.id == id) {
          return updatedRequest;
        }
        return req;
      }).toList();
      state = AsyncValue.data(updatedList);
    }
    return updatedRequest;
  }
}

// Fetches a single request by ID
final requestDetailProvider = FutureProvider.family<ServiceRequest, String>((ref, id) async {
  final repository = ref.watch(requestsRepositoryProvider);
  return repository.getRequestById(id);
});
