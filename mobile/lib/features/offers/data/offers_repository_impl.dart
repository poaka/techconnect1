import '../../../../core/network/error_mapper.dart';
import '../../../../shared/models/job_offer.dart';
import '../domain/offers_repository.dart';
import 'offers_remote_data_source.dart';

class OffersRepositoryImpl implements OffersRepository {
  final OffersRemoteDataSource _remoteDataSource;

  OffersRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<JobOffer>> getOffers() async {
    try {
      final res = await _remoteDataSource.getOffers();
      return res.map((e) => JobOffer.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<JobOffer> acceptOffer(String id) async {
    try {
      final res = await _remoteDataSource.acceptOffer(id);
      return JobOffer.fromJson(res);
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<JobOffer> rejectOffer(String id) async {
    try {
      final res = await _remoteDataSource.rejectOffer(id);
      return JobOffer.fromJson(res);
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }
}
