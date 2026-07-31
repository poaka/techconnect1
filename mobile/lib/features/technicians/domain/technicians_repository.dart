import 'category.dart';
import 'city.dart';
import 'technician_filter.dart';
import 'technician_profile.dart';
import 'region.dart';
import 'technician_document.dart';

abstract class TechniciansRepository {
  Future<List<TechnicianProfile>> getTechnicians(TechnicianFilter filter);
  Future<TechnicianProfile> getTechnicianById(String id);
  Future<TechnicianProfile> updateProfile(Map<String, dynamic> data);
  Future<List<Category>> getCategories();
  Future<List<City>> getCities();
  Future<List<Region>> getRegions();
  Future<List<TechnicianDocument>> getMyDocuments();
  Future<TechnicianDocument> uploadDocument(String filePath, String documentType, String fileName);
}
