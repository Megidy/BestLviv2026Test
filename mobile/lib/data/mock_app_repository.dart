import '../models.dart';
import 'app_repository.dart';

class MockAppRepository implements AppRepository {
  const MockAppRepository();

  @override
  UserProfile getCurrentUserProfile() {
    return const UserProfile(
      username: 'J.DOE_WH04',
      role: UserRole.worker,
      locationId: 4,
    );
  }

  @override
  InventoryOverview getInventoryOverview(int locationId) {
    return InventoryOverview(
      locationId: locationId,
      locationLabel: 'WH-${locationId.toString().padLeft(2, '0')}',
      totalUnits: 252,
      lowStockCount: 2,
      items: const [
        InventoryItem(
          id: 2911,
          resourceName: 'Lithium Cells B-2',
          category: 'Energy',
          quantityLabel: '14 units',
          locationLabel: 'Zone C / Rack 04',
          health: InventoryHealth.critical,
        ),
        InventoryItem(
          id: 772,
          resourceName: 'Coolant Pump M1',
          category: 'Cooling',
          quantityLabel: '3 units',
          locationLabel: 'Zone A / Rack 11',
          health: InventoryHealth.low,
        ),
        InventoryItem(
          id: 42,
          resourceName: 'Hydraulic Fluid X-9',
          category: 'Liquids',
          quantityLabel: '42 L',
          locationLabel: 'Tank Bay / 02',
          health: InventoryHealth.healthy,
        ),
        InventoryItem(
          id: 191,
          resourceName: 'Titanium Fasteners',
          category: 'Hardware',
          quantityLabel: '125 units',
          locationLabel: 'Bulk Storage / 06',
          health: InventoryHealth.healthy,
        ),
      ],
    );
  }

  @override
  List<FacilityMapPoint> getMapPoints() {
    return const [
      FacilityMapPoint(
        id: 1,
        name: 'WH-04 Central Terminal',
        latitude: 49.8397,
        longitude: 24.0297,
        type: MapPointType.warehouse,
        status: MapPointStatus.critical,
        alertCount: 3,
      ),
      FacilityMapPoint(
        id: 2,
        name: 'WH-02 North Reserve',
        latitude: 49.8559,
        longitude: 24.0182,
        type: MapPointType.warehouse,
        status: MapPointStatus.normal,
        alertCount: 0,
      ),
      FacilityMapPoint(
        id: 3,
        name: 'WH-05 East Buffer',
        latitude: 49.8320,
        longitude: 24.0700,
        type: MapPointType.warehouse,
        status: MapPointStatus.elevated,
        alertCount: 1,
      ),
      FacilityMapPoint(
        id: 4,
        name: 'Clinic Hub A',
        latitude: 49.8426,
        longitude: 24.0411,
        type: MapPointType.customer,
        status: MapPointStatus.predictive,
        alertCount: 2,
      ),
      FacilityMapPoint(
        id: 5,
        name: 'Factory Node 7',
        latitude: 49.8239,
        longitude: 24.0118,
        type: MapPointType.customer,
        status: MapPointStatus.elevated,
        alertCount: 1,
      ),
    ];
  }

  @override
  List<PredictiveAlert> getPredictiveAlerts() {
    return const [
      PredictiveAlert(
        id: 4021,
        resourceName: 'Lithium Cells B-2',
        locationLabel: 'WH-04 / Zone C',
        severity: PredictiveAlertSeverity.critical,
        shortageNote: 'Projected shortage in 2h. Gap: 36 units.',
        updatedLabel: '12m ago',
      ),
      PredictiveAlert(
        id: 3984,
        resourceName: 'Coolant Pump M1',
        locationLabel: 'WH-04 / Rack 11',
        severity: PredictiveAlertSeverity.elevated,
        shortageNote: 'Below safety threshold by 4 units.',
        updatedLabel: '28m ago',
      ),
      PredictiveAlert(
        id: 3912,
        resourceName: 'Titanium Fasteners',
        locationLabel: 'WH-04 / Bulk Storage',
        severity: PredictiveAlertSeverity.predictive,
        shortageNote: 'Demand spike detected for next dispatch cycle.',
        updatedLabel: '1h ago',
      ),
    ];
  }
}
