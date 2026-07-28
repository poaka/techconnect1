import '../../../../shared/models/service_request.dart';

abstract class RequestsRepository {
  Future<List<ServiceRequest>> getRequests();
  Future<ServiceRequest> getRequestById(String id);
  Future<ServiceRequest> createRequest({
    required String technicianId,
    String? categoryId,
    required String description,
    String? address,
  });
  Future<ServiceRequest> updateRequestStatus(String id, RequestStatus status);
}
