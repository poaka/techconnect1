import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/job_offer.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../data/offers_remote_data_source.dart';
import '../../data/offers_repository_impl.dart';
import '../../domain/offers_repository.dart';

final offersRemoteDataSourceProvider = Provider<OffersRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return OffersRemoteDataSource(dioClient.dio);
});

final offersRepositoryProvider = Provider<OffersRepository>((ref) {
  final remoteDataSource = ref.watch(offersRemoteDataSourceProvider);
  return OffersRepositoryImpl(remoteDataSource);
});

final offersListProvider = StateNotifierProvider<OffersListNotifier, AsyncValue<List<JobOffer>>>((ref) {
  final repository = ref.watch(offersRepositoryProvider);
  return OffersListNotifier(repository)..fetchOffers();
});

class OffersListNotifier extends StateNotifier<AsyncValue<List<JobOffer>>> {
  final OffersRepository _repository;

  OffersListNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> fetchOffers() async {
    state = const AsyncValue.loading();
    try {
      final offers = await _repository.getOffers();
      // Only keep actionable (sent) offers
      final pendingOffers = offers.where((o) => o.status == JobOfferStatus.sent).toList();
      state = AsyncValue.data(pendingOffers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> acceptOffer(String id) async {
    await _repository.acceptOffer(id);
    _removeOfferFromState(id);
  }

  Future<void> rejectOffer(String id) async {
    await _repository.rejectOffer(id);
    _removeOfferFromState(id);
  }

  void _removeOfferFromState(String id) {
    if (state.hasValue) {
      final updatedList = state.value!.where((o) => o.id != id).toList();
      state = AsyncValue.data(updatedList);
    }
  }
}
