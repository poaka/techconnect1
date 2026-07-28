import '../../../../shared/models/service_request.dart';
import '../../../../core/network/error_mapper.dart';
import '../domain/requests_repository.dart';
import 'requests_remote_data_source.dart';

class RequestsRepositoryImpl implements RequestsRepository {
  final RequestsRemoteDataSource _remoteDataSource;

  RequestsRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ServiceRequest>> getRequests() async {
    try {
      final res = await _remoteDataSource.getRequests();
      return res.map((e) => ServiceRequest.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<ServiceRequest> getRequestById(String id) async {
    try {
      final res = await _remoteDataSource.getRequestById(id);
      return ServiceRequest.fromJson(res);
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<ServiceRequest> createRequest({
    required String technicianId,
    String? categoryId,
    required String description,
    String? address,
  }) async {
    try {
      final res = await _remoteDataSource.createRequest(
        technicianId: technicianId,
        categoryId: categoryId,
        description: description,
        address: address,
      );
      return ServiceRequest.fromJson(res);
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<ServiceRequest> updateRequestStatus(String id, RequestStatus status) async {
    try {
      final res = await _remoteDataSource.updateRequestStatus(id, status.toSnakeCase());
      return ServiceRequest.fromJson(res);
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }
}
