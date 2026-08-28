import '../../../../shared/models/service_request.dart';

abstract class RequestsRepository {
  Future<List<ServiceRequest>> getRequests();
  Future<ServiceRequest> getRequestById(String id);
  Future<ServiceRequest> createRequest({
    required String categoryId,
    required String cityId,
    required String description,
    String? address,
    double? latitude,
    double? longitude,
    String? imagePath,
  });
  Future<ServiceRequest> cancelRequest(String id);
  Future<ServiceRequest> completeRequest(String id);
  Future<void> updateLocation(String id, double latitude, double longitude);
  Future<Map<String, dynamic>?> getLocation(String id);
}
