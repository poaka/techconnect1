import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000/api'));
  try {
    // Attempt 1: Fetch without category
    print('Fetching page 1...');
    var res = await dio.get('/technicians', queryParameters: {'page': 1, 'limit': 10});
    print("Page 1 count: ${res.data['data']['technicians'].length}");

    // Attempt 2: Fetch with category
    print('Fetching with category...');
    res = await dio.get('/technicians', queryParameters: {'page': 1, 'limit': 10, 'category': '20000000-0000-0000-0000-000000000001'});
    print("Category count: ${res.data['data']['technicians'].length}");
    
    // Attempt 3: Fetch with query
    print('Fetching with query...');
    res = await dio.get('/technicians', queryParameters: {'page': 1, 'limit': 10, 'q': 'sam'});
    print("Query count: ${res.data['data']['technicians'].length}");
    
  } catch (e) {
    if (e is DioException) {
      print('DIO ERROR: ${e.response?.data}');
    } else {
      print('ERROR: $e');
    }
  }
}
