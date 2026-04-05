import 'package:flutter/foundation.dart';

import '../models.dart';

abstract class AppRepository {
  const AppRepository();

  ValueListenable<bool> get isOnlineListenable;
  ValueListenable<int> get pendingMutationCountListenable;
  ValueListenable<bool> get isSyncingQueueListenable;

  Future<int> processPendingMutations();

  Future<UserProfile?> tryRestoreSession();
  Future<UserProfile> login({
    required String username,
    required String password,
  });
  Future<void> logout();
  Future<UserProfile> getCurrentUserProfile();
  Future<InventoryOverview> getInventoryOverview(int locationId);
  Future<List<FacilityMapPoint>> getMapPoints();
  Future<List<PredictiveAlert>> getPredictiveAlerts();
  Future<void> dismissPredictiveAlert(int alertId);
  Future<void> createDeliveryRequest({
    required int destinationId,
    required int resourceId,
    required int quantity,
    required UrgencyLevel urgency,
    DateTime? arriveTill,
  });
  Future<void> recordDemandReading({
    required int pointId,
    required int resourceId,
    required num quantity,
    DemandReadingSource source = DemandReadingSource.manual,
    DateTime? recordedAt,
  });
  Future<DemandReadingFeed> getDemandReadings({
    required int pointId,
    int page = 1,
    int pageSize = 20,
  });
  Future<RebalancingProposalDetail> getRebalancingProposal(int proposalId);
  Future<void> approveRebalancingProposal(int proposalId);
  Future<void> dismissRebalancingProposal(int proposalId);
  Future<DeliveryRequestList> getDeliveryRequests({
    String? status,
    String? priority,
    int page = 1,
    int pageSize = 20,
  });
  Future<DeliveryRequestDetail> getDeliveryRequestDetail(int requestId);
  Future<void> escalateDeliveryRequest(int requestId);
  Future<void> updateDeliveryRequestItem({
    required int requestId,
    required int resourceId,
    required num quantity,
  });
  Future<void> cancelDeliveryRequest(int requestId);
  Future<void> deliverDeliveryRequest(int requestId);
  Future<void> approveAllAllocations(int requestId);
  Future<int> allocatePendingRequests();
  Future<AllocationList> getAllocations({
    String? status,
    int? requestId,
    int page = 1,
    int pageSize = 20,
  });
  Future<void> approveAllocation(int allocationId);
  Future<void> dispatchAllocation(int allocationId);
  Future<void> rejectAllocation({
    required int allocationId,
    required String reason,
  });
  Future<List<NearestStockResult>> getNearestStock({
    required int resourceId,
    required int pointId,
    num? quantity,
  });
}
