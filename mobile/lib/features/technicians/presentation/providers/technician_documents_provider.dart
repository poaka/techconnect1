import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/technician_document.dart';
import 'technicians_providers.dart';

final technicianDocumentsProvider = FutureProvider.autoDispose<List<TechnicianDocument>>((ref) async {
  final repository = ref.watch(techniciansRepositoryProvider);
  return await repository.getMyDocuments();
});

final uploadDocumentProvider = Provider.autoDispose((ref) {
  return (String filePath, String documentType, String fileName) async {
    final repository = ref.read(techniciansRepositoryProvider);
    await repository.uploadDocument(filePath, documentType, fileName);
    ref.invalidate(technicianDocumentsProvider);
  };
});
