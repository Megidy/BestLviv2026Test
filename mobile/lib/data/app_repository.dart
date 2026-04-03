import '../models.dart';

abstract class AppRepository {
  const AppRepository();

  UserProfile getCurrentUserProfile();
  InventoryOverview getInventoryOverview(int locationId);
  List<FacilityMapPoint> getMapPoints();
  List<PredictiveAlert> getPredictiveAlerts();
}
