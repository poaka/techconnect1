import '../../../core/network/dio_client.dart';
import '../../auth/domain/app_user.dart';
import '../../technicians/domain/category.dart';
import '../../technicians/domain/technician_profile.dart';
import '../../technicians/domain/region.dart';
import '../../technicians/domain/city.dart';
import '../domain/platform_stats.dart';
import '../domain/report.dart';
import '../domain/technician_document.dart';

class AdminRemoteDataSource {
  final DioClient _client;

  AdminRemoteDataSource(this._client);

  Future<PlatformStats> getPlatformStats() async {
    final response = await _client.get('/admin/stats');
    final data = response.data['data'] as Map<String, dynamic>;
    return PlatformStats.fromJson(data);
  }

  Future<List<TechnicianDocument>> getPendingVerifications() async {
    final response = await _client.get('/admin/verifications');
    final data = response.data['data'] as List<dynamic>;
    return data.map((json) => TechnicianDocument.fromJson(json)).toList();
  }

  Future<List<TechnicianDocument>> getRejectedVerifications() async {
    final response = await _client.get('/admin/verifications/rejected');
    final data = response.data['data'] as List<dynamic>;
    return data.map((json) => TechnicianDocument.fromJson(json)).toList();
  }

  Future<void> reviewDocument({
    required String documentId,
    required String status,
    String? rejectionReason,
  }) async {
    await _client.patch(
      '/admin/verifications/$documentId',
      data: {
        'status': status,
        if (rejectionReason != null && rejectionReason.isNotEmpty)
          'rejectionReason': rejectionReason,
      },
    );
  }

  Future<List<AppUser>> getUsers({String? role}) async {
    final queryParams = role != null ? {'role': role} : null;
    final response = await _client.get('/admin/users', queryParameters: queryParams);
    final data = response.data['data'] as List<dynamic>;
    return data.map((json) => AppUser.fromJson(json)).toList();
  }

  Future<List<TechnicianProfile>> getTechnicians() async {
    final response = await _client.get('/admin/technicians');
    final data = response.data['data'] as List<dynamic>;
    return data.map((json) => TechnicianProfile.fromJson(json)).toList();
  }

  Future<List<Category>> getCategories() async {
    final response = await _client.get('/admin/categories');
    final data = response.data['data'] as List<dynamic>;
    return data.map((json) => Category.fromJson(json)).toList();
  }

  Future<Category> createCategory(Map<String, dynamic> data) async {
    final response = await _client.post('/admin/categories', data: data);
    return Category.fromJson(response.data['data']);
  }

  Future<Category> updateCategory(String id, Map<String, dynamic> data) async {
    final response = await _client.put('/admin/categories/$id', data: data);
    return Category.fromJson(response.data['data']);
  }

  Future<void> deleteCategory(String id) async {
    await _client.delete('/admin/categories/$id');
  }

  Future<List<Report>> getReports({String? status}) async {
    final queryParams = status != null ? {'status': status} : null;
    final response = await _client.get('/reports/admin', queryParameters: queryParams);
    final data = response.data['data'] as List<dynamic>;
    return data.map((json) => Report.fromJson(json)).toList();
  }

  Future<Report> resolveReport(String id, String actionTaken) async {
    final response = await _client.patch('/reports/admin/$id/resolve', data: {
      'action_taken': actionTaken,
    });
    return Report.fromJson(response.data['data']);
  }

  Future<void> deleteUser(String id) async {
    await _client.delete('/admin/users/$id');
  }

  Future<Region> createRegion(Map<String, dynamic> data) async {
    final response = await _client.post('/admin/regions', data: data);
    return Region.fromJson(response.data['data']);
  }

  Future<Region> updateRegion(String id, Map<String, dynamic> data) async {
    final response = await _client.put('/admin/regions/$id', data: data);
    return Region.fromJson(response.data['data']);
  }

  Future<void> deleteRegion(String id) async {
    await _client.delete('/admin/regions/$id');
  }

  Future<City> createCity(Map<String, dynamic> data) async {
    final response = await _client.post('/admin/cities', data: data);
    return City.fromJson(response.data['data']);
  }

  Future<City> updateCity(String id, Map<String, dynamic> data) async {
    final response = await _client.put('/admin/cities/$id', data: data);
    return City.fromJson(response.data['data']);
  }

  Future<void> deleteCity(String id) async {
    await _client.delete('/admin/cities/$id');
  }
}
