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
    required String categoryId,
    required String cityId,
    required String description,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final res = await _remoteDataSource.createRequest(
        categoryId: categoryId,
        cityId: cityId,
        description: description,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      return ServiceRequest.fromJson(res);
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<ServiceRequest> cancelRequest(String id) async {
    try {
      final res = await _remoteDataSource.cancelRequest(id);
      return ServiceRequest.fromJson(res);
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<ServiceRequest> completeRequest(String id) async {
    try {
      final res = await _remoteDataSource.completeRequest(id);
      return ServiceRequest.fromJson(res);
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }
}
