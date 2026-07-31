import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/category.dart';
import '../domain/city.dart';
import '../domain/region.dart';
import '../domain/technician_document.dart';
import '../domain/technician_filter.dart';
import '../domain/technician_profile.dart';

class TechniciansRemoteDataSource {
  final DioClient _client;

  TechniciansRemoteDataSource(this._client);

  Future<List<TechnicianProfile>> getTechnicians(TechnicianFilter filter) async {
    final response = await _client.get(
      '/technicians',
      queryParameters: filter.toQueryParameters(),
    );
    final responseData = response.data['data'] as Map<String, dynamic>;
    final dataList = responseData['technicians'] as List<dynamic>;
    return dataList.map((item) => TechnicianProfile.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<TechnicianProfile> getTechnicianById(String id) async {
    final response = await _client.get('/technicians/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return TechnicianProfile.fromJson(data);
  }

  Future<TechnicianProfile> updateProfile(Map<String, dynamic> data) async {
    final response = await _client.put(
      '/technicians/me/profile',
      data: data,
    );
    final responseData = response.data['data'] as Map<String, dynamic>;
    return TechnicianProfile.fromJson(responseData);
  }

  Future<List<Category>> getCategories() async {
    final response = await _client.get('/technicians/categories');
    final dataList = response.data['data'] as List<dynamic>;
    return dataList.map((item) => Category.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<City>> getCities() async {
    final response = await _client.get('/technicians/cities');
    final dataList = response.data['data'] as List<dynamic>;
    return dataList.map((item) => City.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<Region>> getRegions() async {
    final response = await _client.get('/technicians/regions');
    final dataList = response.data['data'] as List<dynamic>;
    return dataList.map((item) => Region.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<TechnicianDocument>> getMyDocuments() async {
    final response = await _client.get('/technicians/me/documents');
    final dataList = response.data['data'] as List<dynamic>;
    return dataList.map((item) => TechnicianDocument.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<TechnicianDocument> uploadDocument(String filePath, String documentType, String fileName) async {
    final formData = FormData.fromMap({
      'documentType': documentType,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    
    final response = await _client.post(
      '/technicians/me/documents',
      data: formData,
    );
    
    final data = response.data['data'] as Map<String, dynamic>;
    return TechnicianDocument.fromJson(data);
  }
}
