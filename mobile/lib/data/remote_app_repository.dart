import 'package:flutter/foundation.dart';

import '../models.dart';
import 'api_exception.dart';
import 'app_api_client.dart';
import 'app_api_config.dart';
import 'app_repository.dart';
import 'swagger_dtos.dart';

class RemoteAppRepository implements AppRepository {
  RemoteAppRepository({
    AppApiClient? apiClient,
  }) : _apiClient = apiClient ?? AppApiClient();

  final AppApiClient _apiClient;

  @override
  ValueListenable<bool> get isOnlineListenable => _apiClient.isOnlineListenable;

    @override
    ValueListenable<int> get pendingMutationCountListenable =>
      _apiClient.pendingMutationCountListenable;

    @override
    ValueListenable<bool> get isSyncingQueueListenable =>
      _apiClient.isSyncingQueueListenable;

    @override
    Future<int> processPendingMutations() => _apiClient.processPendingMutations();

  @override
  Future<UserProfile?> tryRestoreSession() async {
    final token = await _apiClient.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      return await getCurrentUserProfile();
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await _apiClient.clearToken();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<UserProfile> login({
    required String username,
    required String password,
  }) async {
    final payload = await _apiClient.post(
      AppApiConfig.authLoginPath,
      authorized: false,
      body: <String, Object?>{
        'username': username,
        'password': password,
      },
    );

    final token = _readTokenFromPayload(payload);
    if (token == null) {
      throw const ApiException(message: 'Login succeeded without a token.');
    }

    await _apiClient.saveToken(token);
    return getCurrentUserProfile();
  }

  @override
  Future<void> logout() => _apiClient.clearToken();

  @override
  Future<UserProfile> getCurrentUserProfile() async {
    final payload = await _apiClient.get(AppApiConfig.authMePath);
    final map = _asMap(payload);

    return UserProfile(
      username: _readString(map, const ['username']) ?? 'unknown_user',
      role: _parseUserRole(_readString(map, const ['role'])),
      locationId: _readInt(map, const ['location_id', 'warehouse_id']) ?? 0,
    );
  }

  @override
  Future<InventoryOverview> getInventoryOverview(int locationId) async {
    final payload = await _apiClient.get(
      '${AppApiConfig.inventoryPath}/$locationId',
      queryParameters: const <String, Object?>{
        'page': 1,
        'pageSize': 50,
      },
    );

    final map = _asMap(payload);
    final units = _asList(
      map['inventory_units'] ?? map['items'] ?? payload,
    );

    final items = units
        .map(_parseInventoryItem)
        .whereType<InventoryItem>()
        .toList();

    final totalUnits =
        _readInt(map, const ['total']) ??
        items.fold<int>(
          0,
          (sum, item) => sum + item.quantityValue.round(),
        );
    final lowStockCount = items
        .where(
          (item) =>
              item.health == InventoryHealth.low ||
              item.health == InventoryHealth.critical,
        )
        .length;

    return InventoryOverview(
      locationId: locationId,
      locationLabel: 'WH-${locationId.toString().padLeft(2, '0')}',
      totalUnits: totalUnits,
      lowStockCount: lowStockCount,
      items: items,
    );
  }

  @override
  Future<List<FacilityMapPoint>> getMapPoints() async {
    final payload = await _apiClient.get(AppApiConfig.mapPointsPath);
    final map = _asMap(payload);
    final items = _asList(map['points'] ?? map['items'] ?? payload);

    return items
        .map(_parseMapPoint)
        .whereType<FacilityMapPoint>()
        .toList();
  }

  @override
  Future<List<PredictiveAlert>> getPredictiveAlerts() async {
    final payload = await _apiClient.get(
      AppApiConfig.predictiveAlertsPath,
      queryParameters: const <String, Object?>{
        'page': 1,
        'pageSize': 20,
      },
    );

    final map = _asMap(payload);
    final items = _asList(map['alerts'] ?? map['items'] ?? payload);
    return items
        .map(_parsePredictiveAlert)
        .whereType<PredictiveAlert>()
        .toList();
  }

  @override
  Future<void> dismissPredictiveAlert(int alertId) {
    return _apiClient.post(
      '${AppApiConfig.predictiveAlertsPath}/$alertId/dismiss',
    );
  }

  @override
  Future<void> createDeliveryRequest({
    required int destinationId,
    required int resourceId,
    required int quantity,
    required UrgencyLevel urgency,
    DateTime? arriveTill,
  }) async {
    if (urgency == UrgencyLevel.urgent && arriveTill == null) {
      throw const ApiException(
        message: 'Urgent requests require an arrive-by date and time.',
      );
    }

    await _apiClient.post(
      AppApiConfig.deliveryRequestsPath,
      body: <String, Object?>{
        'destination_id': destinationId,
        'priority': _urgencyToApiValue(urgency),
        'items': <Map<String, Object?>>[
          <String, Object?>{
            'resource_id': resourceId,
            'quantity': quantity,
          },
        ],
        if (arriveTill != null) 'arrive_till': arriveTill.toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<void> recordDemandReading({
    required int pointId,
    required int resourceId,
    required num quantity,
    DemandReadingSource source = DemandReadingSource.manual,
    DateTime? recordedAt,
  }) {
    return _apiClient.post(
      AppApiConfig.demandReadingsPath,
      body: <String, Object?>{
        'point_id': pointId,
        'resource_id': resourceId,
        'quantity': quantity,
        'source': _demandSourceToApiValue(source),
        if (recordedAt != null) 'recorded_at': recordedAt.toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<DemandReadingFeed> getDemandReadings({
    required int pointId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final payload = await _apiClient.get(
      '${AppApiConfig.demandReadingsPath}/$pointId',
      queryParameters: <String, Object?>{
        'page': page,
        'pageSize': pageSize,
      },
    );

    final map = _asMap(payload);
    final readings = _asList(
      map['readings'] ?? map['items'] ?? payload,
    ).map(_parseDemandReading).whereType<DemandReadingRecord>().toList();

    return DemandReadingFeed(
      readings: readings,
      total: _readInt(map, const ['total']) ?? readings.length,
    );
  }

  @override
  Future<RebalancingProposalDetail> getRebalancingProposal(int proposalId) async {
    final payload = await _apiClient.get(
      '${AppApiConfig.rebalancingProposalsPath}/$proposalId',
    );
    final proposal = _parseRebalancingProposal(payload);
    if (proposal == null) {
      throw const ApiException(
        message: 'Rebalancing proposal details are unavailable.',
      );
    }
    return proposal;
  }

  @override
  Future<void> approveRebalancingProposal(int proposalId) {
    return _apiClient.post(
      '${AppApiConfig.rebalancingProposalsPath}/$proposalId/approve',
    );
  }

  @override
  Future<void> dismissRebalancingProposal(int proposalId) {
    return _apiClient.post(
      '${AppApiConfig.rebalancingProposalsPath}/$proposalId/dismiss',
    );
  }

  @override
  Future<DeliveryRequestList> getDeliveryRequests({
    String? status,
    String? priority,
    int page = 1,
    int pageSize = 20,
  }) async {
    final payload = await _apiClient.get(
      AppApiConfig.deliveryRequestsPath,
      queryParameters: <String, Object?>{
        if (status != null && status.trim().isNotEmpty) 'status': status,
        if (priority != null && priority.trim().isNotEmpty)
          'priority': priority,
        'page': page,
        'pageSize': pageSize,
      },
    );

    final map = _asMap(payload);
    final requests = _asList(map['requests'] ?? map['items'] ?? payload)
        .map(_parseDeliveryRequestSummary)
        .whereType<DeliveryRequestSummary>()
        .toList();

    return DeliveryRequestList(
      requests: requests,
      total: _readInt(map, const ['total']) ?? requests.length,
    );
  }

  @override
  Future<DeliveryRequestDetail> getDeliveryRequestDetail(int requestId) async {
    final payload = await _apiClient.get(
      '${AppApiConfig.deliveryRequestsPath}/$requestId',
    );
    final map = _asMap(payload);
    final request = _parseDeliveryRequestSummary(map);
    if (request == null) {
      throw const ApiException(
        message: 'Delivery request details are unavailable.',
      );
    }

    final items = _asList(map['items'])
        .map(_parseDeliveryRequestItem)
        .whereType<DeliveryRequestItem>()
        .toList();
    final allocations = _asList(map['allocations'])
        .map(_parseAllocationRecord)
        .whereType<AllocationRecord>()
        .toList();

    return DeliveryRequestDetail(
      request: request,
      items: items,
      allocations: allocations,
    );
  }

  @override
  Future<void> escalateDeliveryRequest(int requestId) {
    return _apiClient.post(
      '${AppApiConfig.deliveryRequestsPath}/$requestId/escalate',
    );
  }

  @override
  Future<void> updateDeliveryRequestItem({
    required int requestId,
    required int resourceId,
    required num quantity,
  }) {
    return _apiClient.patch(
      '${AppApiConfig.deliveryRequestsPath}/$requestId/items',
      body: <String, Object?>{
        'resource_id': resourceId,
        'quantity': quantity,
      },
    );
  }

  @override
  Future<void> cancelDeliveryRequest(int requestId) {
    return _apiClient.post(
      '${AppApiConfig.deliveryRequestsPath}/$requestId/cancel',
    );
  }

  @override
  Future<void> deliverDeliveryRequest(int requestId) {
    return _apiClient.post(
      '${AppApiConfig.deliveryRequestsPath}/$requestId/deliver',
    );
  }

  @override
  Future<void> approveAllAllocations(int requestId) {
    return _apiClient.post(
      '${AppApiConfig.deliveryRequestsPath}/$requestId/approve-all',
    );
  }

  @override
  Future<int> allocatePendingRequests() async {
    final payload = await _apiClient.post(
      '${AppApiConfig.deliveryRequestsPath}/allocate',
    );
    final map = _asMap(payload);
    return _readInt(map, const ['allocated']) ?? 0;
  }

  @override
  Future<AllocationList> getAllocations({
    String? status,
    int? requestId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final payload = await _apiClient.get(
      AppApiConfig.allocationsPath,
      queryParameters: <String, Object?>{
        if (status != null && status.trim().isNotEmpty) 'status': status,
        'request_id': requestId,
        'page': page,
        'pageSize': pageSize,
      },
    );

    final map = _asMap(payload);
    final allocations = _asList(
      map['allocations'] ?? map['items'] ?? payload,
    ).map(_parseAllocationRecord).whereType<AllocationRecord>().toList();

    return AllocationList(
      allocations: allocations,
      total: _readInt(map, const ['total']) ?? allocations.length,
    );
  }

  @override
  Future<void> approveAllocation(int allocationId) {
    return _apiClient.post(
      '${AppApiConfig.allocationsPath}/$allocationId/approve',
    );
  }

  @override
  Future<void> dispatchAllocation(int allocationId) {
    return _apiClient.post(
      '${AppApiConfig.allocationsPath}/$allocationId/dispatch',
    );
  }

  @override
  Future<void> rejectAllocation({
    required int allocationId,
    required String reason,
  }) {
    return _apiClient.post(
      '${AppApiConfig.allocationsPath}/$allocationId/reject',
      body: <String, Object?>{
        'reason': reason,
      },
    );
  }

  @override
  Future<List<NearestStockResult>> getNearestStock({
    required int resourceId,
    required int pointId,
    num? quantity,
  }) async {
    final payload = await _apiClient.get(
      AppApiConfig.stockNearestPath,
      queryParameters: <String, Object?>{
        'resource_id': resourceId,
        'point_id': pointId,
        'quantity': quantity,
      },
    );

    final map = _asMap(payload);
    final items = _asList(
      map['warehouses'] ?? map['items'] ?? map['results'] ?? payload,
    );

    return items
        .map(_parseNearestStockResult)
        .whereType<NearestStockResult>()
        .toList();
  }

  String? _readTokenFromPayload(dynamic payload) {
    if (payload is String && payload.trim().isNotEmpty) {
      return payload;
    }

    final map = _asMap(payload);
    return _readString(
      map,
      const ['token', 'access_token', 'jwt', 'bearer'],
    );
  }

  InventoryItem? _parseInventoryItem(dynamic raw) {
    final unit = _asMap(raw);
    if (unit.isEmpty) {
      return null;
    }

    final inventory = _asMap(unit['inventory']);
    final resource = _asMap(unit['resource']);
    final quantity = _readNum(inventory, const ['quantity']) ?? 0;
    final unitMeasure = _readString(
      resource,
      const ['unit_measure', 'unit', 'measure'],
    ) ??
        'units';

    return InventoryItem(
      id: _readInt(inventory, const ['id']) ??
          _readInt(resource, const ['id']) ??
          0,
      resourceId: _readInt(resource, const ['id']) ??
          _readInt(inventory, const ['resource_id']) ??
          0,
      resourceName: _readString(resource, const ['name']) ?? 'Unnamed resource',
      category:
          _readString(resource, const ['category']) ?? 'Uncategorized resource',
      quantityValue: quantity,
      unitLabel: unitMeasure,
      locationLabel: _formatInventoryLocation(inventory),
      health: _inventoryHealthFor(quantity),
    );
  }

  FacilityMapPoint? _parseMapPoint(dynamic raw) {
    final map = _asMap(raw);
    if (map.isEmpty) {
      return null;
    }

    final typeRaw = _readString(
      map,
      const ['type', 'point_type', 'location_type'],
    );
    final statusRaw = _readString(
      map,
      const ['status', 'severity', 'urgency', 'map_status', 'point_status'],
    );

    return FacilityMapPoint(
      id: _readInt(map, const ['id']) ?? 0,
      name: _readString(map, const ['name']) ?? 'Unknown point',
      latitude: _readNum(map, const ['lat', 'latitude'])?.toDouble() ?? 0,
      longitude: _readNum(map, const ['lng', 'longitude'])?.toDouble() ?? 0,
      type: _parseMapPointType(typeRaw),
      status: _parseMapPointStatus(statusRaw),
      alertCount: _readAlertCount(map) ?? 0,
    );
  }

  PredictiveAlert? _parsePredictiveAlert(dynamic raw) {
    final map = _asMap(raw);
    if (map.isEmpty) {
      return null;
    }
    final dto = PredictiveAlertDto.fromMap(map);

    return PredictiveAlert(
      id: dto.id,
      resourceName: dto.resourceName,
      locationLabel: dto.locationLabel,
      severity: _parseAlertSeverity(dto.severity),
      shortageNote: _buildShortageNote(
        predictedShortfallAt: dto.predictedShortfallAt,
        confidence: dto.confidence,
      ),
      updatedLabel: _formatRelative(
        dto.updatedAt ?? dto.predictedShortfallAt,
      ),
      pointId: dto.pointId,
      proposalId: dto.proposalId,
      confidence: dto.confidence,
      predictedShortfallAt: dto.predictedShortfallAt,
    );
  }

  DeliveryRequestSummary? _parseDeliveryRequestSummary(dynamic raw) {
    final map = _asMap(raw);
    if (map.isEmpty) {
      return null;
    }
    final dto = DeliveryRequestSummaryDto.fromMap(map);

    return DeliveryRequestSummary(
      id: dto.id,
      destinationId: dto.destinationId,
      resourceId: dto.resourceId,
      userId: dto.userId,
      quantity: dto.quantity,
      priority: _parseDeliveryPriority(dto.priority),
      status: _parseDeliveryRequestStatus(dto.status),
      arriveTill: dto.arriveTill,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  DeliveryRequestItem? _parseDeliveryRequestItem(dynamic raw) {
    final map = _asMap(raw);
    if (map.isEmpty) {
      return null;
    }
    final dto = DeliveryRequestItemDto.fromMap(map);

    return DeliveryRequestItem(
      id: dto.id,
      requestId: dto.requestId,
      resourceId: dto.resourceId,
      quantity: dto.quantity,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  AllocationRecord? _parseAllocationRecord(dynamic raw) {
    final map = _asMap(raw);
    if (map.isEmpty) {
      return null;
    }
    final dto = AllocationRecordDto.fromMap(map);

    return AllocationRecord(
      id: dto.id,
      requestId: dto.requestId,
      sourceWarehouseId: dto.sourceWarehouseId,
      resourceId: dto.resourceId,
      quantity: dto.quantity,
      status: _parseAllocationStatus(dto.status),
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  DemandReadingRecord? _parseDemandReading(dynamic raw) {
    final map = _asMap(raw);
    if (map.isEmpty) {
      return null;
    }
    final dto = DemandReadingDto.fromMap(map);

    return DemandReadingRecord(
      id: dto.id,
      pointId: dto.pointId,
      resourceId: dto.resourceId,
      quantity: dto.quantity,
      source: _parseDemandSource(dto.source),
      recordedAt: dto.recordedAt,
      createdAt: dto.createdAt,
    );
  }

  RebalancingProposalDetail? _parseRebalancingProposal(dynamic raw) {
    final map = _asMap(raw);
    if (map.isEmpty) {
      return null;
    }
    final dto = RebalancingProposalDto.fromMap(map);

    final transfers = dto.transfers
        .map(
          (transfer) => RebalancingTransfer(
            id: transfer.id,
            proposalId: transfer.proposalId,
            fromWarehouseId: transfer.fromWarehouseId,
            quantity: transfer.quantity,
            estimatedArrivalHours: transfer.estimatedArrivalHours,
            createdAt: transfer.createdAt,
          ),
        )
        .toList();

    return RebalancingProposalDetail(
      id: dto.id,
      resourceId: dto.resourceId,
      targetPointId: dto.targetPointId,
      status: _parseProposalStatus(dto.status),
      confidence: dto.confidence,
      urgency: dto.urgency,
      transfers: transfers,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  NearestStockResult? _parseNearestStockResult(dynamic raw) {
    final map = _asMap(raw);
    if (map.isEmpty) {
      return null;
    }
    final dto = NearestStockResultDto.fromMap(map);

    return NearestStockResult(
      warehouseId: dto.warehouseId,
      warehouseLabel: dto.warehouseLabel,
      resourceId: dto.resourceId,
      availableQuantity: dto.availableQuantity,
      distanceKm: dto.distanceKm,
      etaHours: dto.etaHours,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), item),
      );
    }
    return const <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List<dynamic>) {
      return value;
    }
    if (value is List) {
      return List<dynamic>.from(value);
    }
    return const <dynamic>[];
  }

  String? _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  int? _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  num? _readNum(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) {
        return value;
      }
      if (value is String) {
        final parsed = num.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  UserRole _parseUserRole(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'dispatcher':
        return UserRole.dispatcher;
      case 'worker':
      default:
        return UserRole.worker;
    }
  }

  InventoryHealth _inventoryHealthFor(num quantity) {
    if (quantity <= 0) {
      return InventoryHealth.critical;
    }
    if (quantity <= 10) {
      return InventoryHealth.low;
    }
    return InventoryHealth.healthy;
  }

  String _formatInventoryLocation(Map<String, dynamic> inventory) {
    final locationId = _readInt(inventory, const ['location_id']) ?? 0;
    return 'Warehouse location #$locationId';
  }

  MapPointType _parseMapPointType(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return MapPointType.warehouse;
    }
    if (normalized.contains('customer')) {
      return MapPointType.customer;
    }
    return MapPointType.warehouse;
  }

  MapPointStatus _parseMapPointStatus(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return MapPointStatus.normal;
    }
    if (normalized.contains('critical')) {
      return MapPointStatus.critical;
    }
    if (normalized.contains('urgent') || normalized.contains('high')) {
      return MapPointStatus.critical;
    }
    if (normalized.contains('elevated') ||
        normalized.contains('warning') ||
        normalized.contains('low') ||
        normalized.contains('medium')) {
      return MapPointStatus.elevated;
    }
    if (normalized.contains('predictive') || normalized.contains('forecast')) {
      return MapPointStatus.predictive;
    }
    if (normalized.contains('normal')) {
      return MapPointStatus.normal;
    }
    return MapPointStatus.normal;
  }

  int? _readAlertCount(Map<String, dynamic> map) {
    final direct = _readInt(
      map,
      const ['alert_count', 'alerts_count', 'open_alerts', 'alerts_total'],
    );
    if (direct != null) {
      return direct;
    }

    final rawAlerts = map['alerts'] ?? map['active_alerts'];
    if (rawAlerts is List) {
      return rawAlerts.length;
    }
    if (rawAlerts is String) {
      return int.tryParse(rawAlerts.trim());
    }
    return null;
  }

  PredictiveAlertSeverity _parseAlertSeverity(String? value) {
    switch (value?.toLowerCase()) {
      case 'critical':
      case 'urgent':
        return PredictiveAlertSeverity.critical;
      case 'elevated':
      case 'warning':
        return PredictiveAlertSeverity.elevated;
      case 'predictive':
      default:
        return PredictiveAlertSeverity.predictive;
    }
  }

  DeliveryPriority _parseDeliveryPriority(String? value) {
    switch (value?.toLowerCase()) {
      case 'normal':
        return DeliveryPriority.normal;
      case 'elevated':
        return DeliveryPriority.elevated;
      case 'critical':
        return DeliveryPriority.critical;
      case 'urgent':
        return DeliveryPriority.urgent;
      default:
        return DeliveryPriority.unknown;
    }
  }

  DeliveryRequestStatus _parseDeliveryRequestStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return DeliveryRequestStatus.pending;
      case 'allocated':
        return DeliveryRequestStatus.allocated;
      case 'in_transit':
        return DeliveryRequestStatus.inTransit;
      case 'delivered':
        return DeliveryRequestStatus.delivered;
      case 'cancelled':
        return DeliveryRequestStatus.cancelled;
      default:
        return DeliveryRequestStatus.unknown;
    }
  }

  AllocationStatus _parseAllocationStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'planned':
        return AllocationStatus.planned;
      case 'approved':
        return AllocationStatus.approved;
      case 'in_transit':
        return AllocationStatus.inTransit;
      case 'delivered':
        return AllocationStatus.delivered;
      case 'cancelled':
        return AllocationStatus.cancelled;
      default:
        return AllocationStatus.unknown;
    }
  }

  DemandReadingSource _parseDemandSource(String? value) {
    switch (value?.toLowerCase()) {
      case 'manual':
        return DemandReadingSource.manual;
      case 'sensor':
        return DemandReadingSource.sensor;
      case 'predicted':
        return DemandReadingSource.predicted;
      default:
        return DemandReadingSource.unknown;
    }
  }

  ProposalStatus _parseProposalStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return ProposalStatus.pending;
      case 'approved':
        return ProposalStatus.approved;
      case 'dismissed':
        return ProposalStatus.dismissed;
      default:
        return ProposalStatus.unknown;
    }
  }

  String _urgencyToApiValue(UrgencyLevel urgency) {
    return switch (urgency) {
      UrgencyLevel.normal => 'normal',
      UrgencyLevel.elevated => 'elevated',
      UrgencyLevel.critical => 'critical',
      UrgencyLevel.urgent => 'urgent',
    };
  }

  String _demandSourceToApiValue(DemandReadingSource source) {
    return switch (source) {
      DemandReadingSource.manual => 'manual',
      DemandReadingSource.sensor => 'sensor',
      DemandReadingSource.predicted => 'predicted',
      DemandReadingSource.unknown => 'manual',
    };
  }

  String _buildShortageNote({
    required DateTime? predictedShortfallAt,
    required num? confidence,
  }) {
    final parts = <String>[];
    if (predictedShortfallAt != null) {
      final hours = predictedShortfallAt.difference(DateTime.now()).inHours;
      if (hours > 0) {
        parts.add('Projected shortfall in ${hours}h.');
      }
    }

    if (confidence != null) {
      parts.add('Confidence ${(confidence * 100).round()}%.');
    }

    if (parts.isEmpty) {
      return 'Forecasted shortage detected by predictive analysis.';
    }

    return parts.join(' ');
  }

  String _formatRelative(DateTime? value) {
    if (value == null) {
      return 'just now';
    }

    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 1) {
      return 'just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }
}
