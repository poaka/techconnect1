import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/technicians/domain/technician_filter.dart';
import 'package:mobile/features/technicians/presentation/providers/technicians_providers.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';

void main() async {
  final storage = SecureStorageService();
  final dioClient = DioClient(storageService: storage);
  
  final container = ProviderContainer(
    overrides: [
      dioClientProvider.overrideWithValue(dioClient),
    ]
  );
  
  final notifier = container.read(technicianListNotifierProvider.notifier);
  
  print('Fetching without filter...');
  await notifier.fetchTechnicians(isRefresh: true);
  var state = container.read(technicianListNotifierProvider);
  print('State items: \${state.items.length}, error: \${state.errorMessage}');
  
  print('Fetching with category filter...');
  final filter = const TechnicianFilter(categoryId: '20000000-0000-0000-0000-000000000001');
  await notifier.fetchTechnicians(filter: filter, isRefresh: true);
  state = container.read(technicianListNotifierProvider);
  print('State items: \${state.items.length}, error: \${state.errorMessage}');
  
  print('Done.');
}
