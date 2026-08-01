import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/technicians/domain/technician_filter.dart';
import 'package:mobile/features/technicians/presentation/providers/technicians_providers.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/features/auth/presentation/auth_provider.dart';

void main() async {
  final storage = SecureStorageService();
  final dioClient = DioClient(storageService: storage);
  
  final container = ProviderContainer(
    overrides: [
      dioClientProvider.overrideWithValue(dioClient),
    ]
  );
  
  final notifier = container.read(technicianListNotifierProvider.notifier);
  
  // ignore: avoid_print
  print('Fetching technicians...');
  await notifier.fetchTechnicians(filter: const TechnicianFilter(), isRefresh: true);
  final state = container.read(technicianListNotifierProvider);
  // ignore: avoid_print
  print('Found ${state.items.length} technicians. Error: ${state.errorMessage}');
  
  // ignore: avoid_print
  print('Done.');
}
