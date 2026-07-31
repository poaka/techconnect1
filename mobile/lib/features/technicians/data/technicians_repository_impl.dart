import '../../../core/network/error_mapper.dart';
import '../domain/category.dart';
import '../domain/city.dart';
import '../domain/region.dart';
import '../domain/technician_filter.dart';
import '../domain/technician_profile.dart';
import '../domain/technician_document.dart';
import '../domain/technicians_repository.dart';
import 'technicians_remote_data_source.dart';

class TechniciansRepositoryImpl implements TechniciansRepository {
  final TechniciansRemoteDataSource _remoteDataSource;

  TechniciansRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<TechnicianProfile>> getTechnicians(TechnicianFilter filter) async {
    try {
      return await _remoteDataSource.getTechnicians(filter);
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<TechnicianProfile> getTechnicianById(String id) async {
    try {
      return await _remoteDataSource.getTechnicianById(id);
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<TechnicianProfile> updateProfile(Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.updateProfile(data);
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<Category>> getCategories() async {
    try {
      return await _remoteDataSource.getCategories();
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<City>> getCities() async {
    try {
      return await _remoteDataSource.getCities();
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<Region>> getRegions() async {
    try {
      return await _remoteDataSource.getRegions();
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<List<TechnicianDocument>> getMyDocuments() async {
    try {
      return await _remoteDataSource.getMyDocuments();
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<TechnicianDocument> uploadDocument(String filePath, String documentType, String fileName) async {
    try {
      return await _remoteDataSource.uploadDocument(filePath, documentType, fileName);
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }
}
