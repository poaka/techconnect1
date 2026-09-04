import '../../../../shared/models/job_offer.dart';

abstract class OffersRepository {
  Future<List<JobOffer>> getOffers();
  Future<JobOffer> acceptOffer(String id);
  Future<JobOffer> rejectOffer(String id);
}
