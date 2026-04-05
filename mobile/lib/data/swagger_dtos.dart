class DtoRead {
  const DtoRead._();

  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }

  static int readInt(
    Map<String, dynamic> map,
    List<String> keys, {
    int defaultValue = 0,
  }) {
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
    return defaultValue;
  }

  static num readNum(
    Map<String, dynamic> map,
    List<String> keys, {
    num defaultValue = 0,
  }) {
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
    return defaultValue;
  }

  static String readString(
    Map<String, dynamic> map,
    List<String> keys, {
    String defaultValue = '',
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return defaultValue;
  }

  static DateTime? readDateTime(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed.toLocal();
        }
      }
    }
    return null;
  }
}

class PredictiveAlertDto {
  const PredictiveAlertDto({
    required this.id,
    required this.resourceName,
    required this.locationLabel,
    required this.severity,
    required this.updatedAt,
    this.predictedShortfallAt,
    this.confidence,
    this.proposalId,
  });

  final int id;
  final String resourceName;
  final String locationLabel;
  final String severity;
  final DateTime? updatedAt;
  final DateTime? predictedShortfallAt;
  final num? confidence;
  final int? proposalId;

  factory PredictiveAlertDto.fromMap(Map<String, dynamic> map) {
    final resource = DtoRead.asMap(map['resource']);
    final point = DtoRead.asMap(map['point']);

    final id = DtoRead.readInt(map, const ['id']);
    final resourceName = DtoRead.readString(
      resource,
      const ['name'],
      defaultValue: DtoRead.readString(
        map,
        const ['resource_name', 'name'],
        defaultValue: 'Forecasted resource',
      ),
    );
    final locationLabel = DtoRead.readString(
      point,
      const ['name'],
      defaultValue: DtoRead.readString(
        map,
        const ['location_label', 'location_name'],
        defaultValue: 'Predicted shortage point',
      ),
    );

    final confidenceRaw = map['confidence'];
    final confidence = confidenceRaw is num
        ? confidenceRaw
        : (confidenceRaw is String ? num.tryParse(confidenceRaw) : null);

    final proposalCandidate = map['proposal_id'] ?? map['rebalancing_proposal_id'];
    final proposalId = proposalCandidate is int
        ? proposalCandidate
        : (proposalCandidate is String ? int.tryParse(proposalCandidate) : null);

    return PredictiveAlertDto(
      id: id,
      resourceName: resourceName,
      locationLabel: locationLabel,
      severity: DtoRead.readString(
        map,
        const ['severity', 'urgency', 'status'],
        defaultValue: 'predictive',
      ),
      updatedAt: DtoRead.readDateTime(
        map,
        const ['updated_at', 'created_at'],
      ),
      predictedShortfallAt: DtoRead.readDateTime(
        map,
        const [
          'predicted_shortfall_at',
          'PredictedShortfallAt',
          'shortfall_at',
          'runs_out_at',
        ],
      ),
      confidence: confidence,
      proposalId: proposalId,
    );
  }
}

class DeliveryRequestSummaryDto {
  const DeliveryRequestSummaryDto({
    required this.id,
    required this.destinationId,
    required this.resourceId,
    required this.userId,
    required this.quantity,
    required this.priority,
    required this.status,
    this.arriveTill,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int destinationId;
  final int resourceId;
  final int userId;
  final num quantity;
  final String priority;
  final String status;
  final DateTime? arriveTill;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DeliveryRequestSummaryDto.fromMap(Map<String, dynamic> map) {
    return DeliveryRequestSummaryDto(
      id: DtoRead.readInt(map, const ['id']),
      destinationId: DtoRead.readInt(map, const ['destination_id']),
      resourceId: DtoRead.readInt(map, const ['resource_id']),
      userId: DtoRead.readInt(map, const ['user_id']),
      quantity: DtoRead.readNum(map, const ['quantity']),
      priority: DtoRead.readString(
        map,
        const ['priority'],
        defaultValue: 'unknown',
      ),
      status: DtoRead.readString(
        map,
        const ['status'],
        defaultValue: 'unknown',
      ),
      arriveTill: DtoRead.readDateTime(map, const ['arrive_till']),
      createdAt: DtoRead.readDateTime(map, const ['created_at']),
      updatedAt: DtoRead.readDateTime(map, const ['updated_at']),
    );
  }
}

class DeliveryRequestItemDto {
  const DeliveryRequestItemDto({
    required this.id,
    required this.requestId,
    required this.resourceId,
    required this.quantity,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int requestId;
  final int resourceId;
  final num quantity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DeliveryRequestItemDto.fromMap(Map<String, dynamic> map) {
    return DeliveryRequestItemDto(
      id: DtoRead.readInt(map, const ['id']),
      requestId: DtoRead.readInt(map, const ['request_id']),
      resourceId: DtoRead.readInt(map, const ['resource_id']),
      quantity: DtoRead.readNum(map, const ['quantity']),
      createdAt: DtoRead.readDateTime(map, const ['created_at']),
      updatedAt: DtoRead.readDateTime(map, const ['updated_at']),
    );
  }
}

class AllocationRecordDto {
  const AllocationRecordDto({
    required this.id,
    required this.requestId,
    required this.sourceWarehouseId,
    required this.resourceId,
    required this.quantity,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int requestId;
  final int sourceWarehouseId;
  final int resourceId;
  final num quantity;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AllocationRecordDto.fromMap(Map<String, dynamic> map) {
    return AllocationRecordDto(
      id: DtoRead.readInt(map, const ['id']),
      requestId: DtoRead.readInt(map, const ['request_id']),
      sourceWarehouseId: DtoRead.readInt(map, const ['source_warehouse_id']),
      resourceId: DtoRead.readInt(map, const ['resource_id']),
      quantity: DtoRead.readNum(map, const ['quantity']),
      status: DtoRead.readString(
        map,
        const ['status'],
        defaultValue: 'unknown',
      ),
      createdAt: DtoRead.readDateTime(map, const ['created_at']),
      updatedAt: DtoRead.readDateTime(map, const ['updated_at']),
    );
  }
}

class DemandReadingDto {
  const DemandReadingDto({
    required this.id,
    required this.pointId,
    required this.resourceId,
    required this.quantity,
    required this.source,
    this.recordedAt,
    this.createdAt,
  });

  final int id;
  final int pointId;
  final int resourceId;
  final num quantity;
  final String source;
  final DateTime? recordedAt;
  final DateTime? createdAt;

  factory DemandReadingDto.fromMap(Map<String, dynamic> map) {
    return DemandReadingDto(
      id: DtoRead.readInt(map, const ['id']),
      pointId: DtoRead.readInt(map, const ['point_id']),
      resourceId: DtoRead.readInt(map, const ['resource_id']),
      quantity: DtoRead.readNum(map, const ['quantity']),
      source: DtoRead.readString(
        map,
        const ['source'],
        defaultValue: 'unknown',
      ),
      recordedAt: DtoRead.readDateTime(map, const ['recorded_at']),
      createdAt: DtoRead.readDateTime(map, const ['created_at']),
    );
  }
}

class RebalancingTransferDto {
  const RebalancingTransferDto({
    required this.id,
    required this.proposalId,
    required this.fromWarehouseId,
    required this.quantity,
    this.estimatedArrivalHours,
    this.createdAt,
  });

  final int id;
  final int proposalId;
  final int fromWarehouseId;
  final num quantity;
  final num? estimatedArrivalHours;
  final DateTime? createdAt;

  factory RebalancingTransferDto.fromMap(Map<String, dynamic> map) {
    final etaRaw = map['estimated_arrival_hours'];
    final eta = etaRaw is num
        ? etaRaw
        : (etaRaw is String ? num.tryParse(etaRaw) : null);

    return RebalancingTransferDto(
      id: DtoRead.readInt(map, const ['id']),
      proposalId: DtoRead.readInt(map, const ['proposal_id']),
      fromWarehouseId: DtoRead.readInt(map, const ['from_warehouse_id']),
      quantity: DtoRead.readNum(map, const ['quantity']),
      estimatedArrivalHours: eta,
      createdAt: DtoRead.readDateTime(map, const ['created_at']),
    );
  }
}

class RebalancingProposalDto {
  const RebalancingProposalDto({
    required this.id,
    required this.resourceId,
    required this.targetPointId,
    required this.status,
    required this.confidence,
    required this.urgency,
    required this.transfers,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int resourceId;
  final int targetPointId;
  final String status;
  final num confidence;
  final String urgency;
  final List<RebalancingTransferDto> transfers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory RebalancingProposalDto.fromMap(Map<String, dynamic> map) {
    final transferList = map['transfers'];
    final transfers = transferList is List
        ? transferList
            .map((item) => DtoRead.asMap(item))
            .map(RebalancingTransferDto.fromMap)
            .toList()
        : const <RebalancingTransferDto>[];

    return RebalancingProposalDto(
      id: DtoRead.readInt(map, const ['id']),
      resourceId: DtoRead.readInt(map, const ['resource_id']),
      targetPointId: DtoRead.readInt(map, const ['target_point_id']),
      status: DtoRead.readString(
        map,
        const ['status'],
        defaultValue: 'unknown',
      ),
      confidence: DtoRead.readNum(map, const ['confidence']),
      urgency: DtoRead.readString(
        map,
        const ['urgency'],
        defaultValue: 'unknown',
      ),
      transfers: transfers,
      createdAt: DtoRead.readDateTime(map, const ['created_at']),
      updatedAt: DtoRead.readDateTime(map, const ['updated_at']),
    );
  }
}

class NearestStockResultDto {
  const NearestStockResultDto({
    required this.warehouseId,
    required this.warehouseLabel,
    required this.resourceId,
    required this.availableQuantity,
    this.distanceKm,
    this.etaHours,
  });

  final int warehouseId;
  final String warehouseLabel;
  final int resourceId;
  final num availableQuantity;
  final num? distanceKm;
  final num? etaHours;

  factory NearestStockResultDto.fromMap(Map<String, dynamic> map) {
    final warehouseId = DtoRead.readInt(
      map,
      const ['warehouse_id', 'source_warehouse_id', 'id'],
    );

    final distanceRaw = map['distance_km'] ?? map['distance'];
    final distanceKm = distanceRaw is num
        ? distanceRaw
        : (distanceRaw is String ? num.tryParse(distanceRaw) : null);

    final etaRaw = map['eta_hours'] ?? map['estimated_arrival_hours'];
    final etaHours = etaRaw is num
        ? etaRaw
        : (etaRaw is String ? num.tryParse(etaRaw) : null);

    return NearestStockResultDto(
      warehouseId: warehouseId,
      warehouseLabel: DtoRead.readString(
        map,
        const ['warehouse_name', 'name'],
        defaultValue: 'Warehouse #$warehouseId',
      ),
      resourceId: DtoRead.readInt(map, const ['resource_id']),
      availableQuantity: DtoRead.readNum(
        map,
        const ['available_quantity', 'surplus', 'quantity'],
      ),
      distanceKm: distanceKm,
      etaHours: etaHours,
    );
  }
}
