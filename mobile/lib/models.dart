import 'package:flutter/material.dart';

enum AppScreen {
  login,
  home,
  alerts,
  inventory,
  detail,
  demand,
  demandReadings,
  rebalancingProposals,
  stockNearest,
  requests,
  requestDetail,
  scanner,
  map,
  settings,
}

enum UrgencyLevel {
  normal,
  elevated,
  critical,
  urgent,
}

enum UserRole {
  worker,
  dispatcher,
  admin,
}

enum PredictiveAlertSeverity {
  elevated,
  critical,
  predictive,
}

enum InventoryHealth {
  healthy,
  low,
  critical,
}

enum DeliveryPriority {
  normal,
  elevated,
  critical,
  urgent,
  unknown,
}

enum DeliveryRequestStatus {
  pending,
  allocated,
  inTransit,
  delivered,
  cancelled,
  unknown,
}

enum AllocationStatus {
  planned,
  approved,
  inTransit,
  delivered,
  cancelled,
  unknown,
}

enum DemandReadingSource {
  manual,
  sensor,
  predicted,
  unknown,
}

enum ProposalStatus {
  pending,
  approved,
  dismissed,
  unknown,
}

enum MapPointType {
  warehouse,
  customer,
}

enum MapPointStatus {
  normal,
  elevated,
  critical,
  predictive,
}

class UserProfile {
  const UserProfile({
    required this.username,
    required this.role,
    required this.locationId,
  });

  final String username;
  final UserRole role;
  final int locationId;

  String get initials {
    final cleaned = username.split('_').first;
    final parts = cleaned.split('.');
    if (parts.length >= 2 &&
        parts.first.isNotEmpty &&
        parts[1].isNotEmpty) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }

    if (cleaned.length >= 2) {
      return cleaned.substring(0, 2).toUpperCase();
    }

    return cleaned.toUpperCase();
  }

  String get roleLabel => switch (role) {
        UserRole.worker => 'Worker',
        UserRole.dispatcher => 'Dispatcher',
        UserRole.admin => 'Admin',
      };

  String get locationLabel => 'WH-${locationId.toString().padLeft(2, '0')}';
}

class PredictiveAlert {
  const PredictiveAlert({
    required this.id,
    required this.resourceName,
    required this.locationLabel,
    required this.severity,
    required this.shortageNote,
    required this.updatedLabel,
    this.proposalId,
    this.confidence,
    this.predictedShortfallAt,
  });

  final int id;
  final String resourceName;
  final String locationLabel;
  final PredictiveAlertSeverity severity;
  final String shortageNote;
  final String updatedLabel;
  final int? proposalId;
  final num? confidence;
  final DateTime? predictedShortfallAt;

  String get severityLabel => switch (severity) {
        PredictiveAlertSeverity.elevated => 'Elevated',
        PredictiveAlertSeverity.critical => 'Critical',
        PredictiveAlertSeverity.predictive => 'Predictive',
      };

  String get confidenceLabel {
    final value = confidence;
    if (value == null) {
      return 'N/A';
    }
    return '${(value * 100).round()}%';
  }

  String get etaLabel {
    final value = predictedShortfallAt;
    if (value == null) {
      return 'N/A';
    }

    final delta = value.difference(DateTime.now());
    if (delta.inMinutes <= 0) {
      return 'due now';
    }

    if (delta.inHours < 1) {
      return '${delta.inMinutes}m';
    }

    final hours = delta.inHours;
    final minutes = delta.inMinutes % 60;
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.resourceId,
    required this.resourceName,
    required this.category,
    required this.quantityValue,
    required this.unitLabel,
    required this.locationLabel,
    required this.health,
  });

  final int id;
  final int resourceId;
  final String resourceName;
  final String category;
  final num quantityValue;
  final String unitLabel;
  final String locationLabel;
  final InventoryHealth health;

  String get normalizedUnitLabel {
    final value = unitLabel.trim();
    return value.isEmpty ? 'units' : value;
  }

  String get quantityValueLabel {
    final value = quantityValue;
    final whole = value % 1 == 0;
    return whole ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  String get quantityLabel => '$quantityValueLabel $normalizedUnitLabel';

  String? get packageSizeLabel => _extractPackageSizeLabel(resourceName);

  String? get approximateBaseAmountLabel => _buildApproximateBaseAmountLabel(
        name: resourceName,
        unitLabel: normalizedUnitLabel,
        quantityValue: quantityValue,
      );

  String get healthLabel => switch (health) {
        InventoryHealth.healthy => 'Healthy',
        InventoryHealth.low => 'Low',
        InventoryHealth.critical => 'Critical',
      };
}

class InventoryOverview {
  const InventoryOverview({
    required this.locationId,
    required this.locationLabel,
    required this.totalUnits,
    required this.lowStockCount,
    required this.items,
  });

  final int locationId;
  final String locationLabel;
  final int totalUnits;
  final int lowStockCount;
  final List<InventoryItem> items;
}

class FacilityMapPoint {
  const FacilityMapPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.status,
    required this.alertCount,
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final MapPointType type;
  final MapPointStatus status;
  final int alertCount;

  String get typeLabel => switch (type) {
        MapPointType.warehouse => 'Warehouse',
        MapPointType.customer => 'Customer',
      };

  String get statusLabel => switch (status) {
        MapPointStatus.normal => 'Normal',
        MapPointStatus.elevated => 'Elevated',
        MapPointStatus.critical => 'Critical',
        MapPointStatus.predictive => 'Predictive',
      };
}

class ResourceRecord {
  const ResourceRecord({
    required this.resourceId,
    required this.name,
    required this.category,
    required this.location,
    required this.quantityValue,
    required this.unitLabel,
    required this.health,
    required this.lastUpdatedLabel,
  });

  final int resourceId;
  final String name;
  final String category;
  final String location;
  final num quantityValue;
  final String unitLabel;
  final InventoryHealth health;
  final String lastUpdatedLabel;

  String get normalizedUnitLabel {
    final value = unitLabel.trim();
    return value.isEmpty ? 'units' : value;
  }

  String get quantityValueLabel {
    final value = quantityValue;
    final whole = value % 1 == 0;
    return whole ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  String get quantityLabel => '$quantityValueLabel $normalizedUnitLabel';

  String? get packageSizeLabel => _extractPackageSizeLabel(name);

  String? get approximateBaseAmountLabel => _buildApproximateBaseAmountLabel(
        name: name,
        unitLabel: normalizedUnitLabel,
        quantityValue: quantityValue,
      );

  String get healthLabel => switch (health) {
        InventoryHealth.healthy => 'Healthy',
        InventoryHealth.low => 'Low',
        InventoryHealth.critical => 'Critical',
      };
}

const Set<String> _packageUnits = <String>{
  'мішок',
  'мішки',
  'bag',
  'bags',
  'pack',
  'packs',
  'упак',
  'упаковка',
  'упаковки',
  'палета',
  'палети',
  'pallet',
  'pallets',
  'box',
  'boxes',
};

final RegExp _packageSizePattern = RegExp(
  r'(\d+(?:[.,]\d+)?)\s*(кг|kg|г|g|л|l|мл|ml)\b',
  caseSensitive: false,
);

String? _extractPackageSizeLabel(String name) {
  final parsed = _parsePackageSizeFromName(name);
  if (parsed == null) {
    return null;
  }
  return '${_formatNumeric(parsed.$1)} ${parsed.$2}';
}

String? _buildApproximateBaseAmountLabel({
  required String name,
  required String unitLabel,
  required num quantityValue,
}) {
  if (!_isPackageUnit(unitLabel)) {
    return null;
  }

  final parsed = _parsePackageSizeFromName(name);
  if (parsed == null) {
    return null;
  }

  final total = quantityValue * parsed.$1;
  return '${_formatNumeric(total)} ${parsed.$2}';
}

bool _isPackageUnit(String rawUnit) {
  final value = rawUnit.trim().toLowerCase();
  return _packageUnits.contains(value);
}

(num, String)? _parsePackageSizeFromName(String name) {
  final match = _packageSizePattern.firstMatch(name);
  if (match == null) {
    return null;
  }

  final amountRaw = match.group(1);
  final unitRaw = match.group(2);
  if (amountRaw == null || unitRaw == null) {
    return null;
  }

  final amount = num.tryParse(amountRaw.replaceAll(',', '.'));
  if (amount == null || amount <= 0) {
    return null;
  }

  final normalizedUnit = _normalizeMeasureUnit(unitRaw);
  return (amount, normalizedUnit);
}

String _normalizeMeasureUnit(String raw) {
  final value = raw.trim().toLowerCase();
  return switch (value) {
    'kg' || 'кг' => 'кг',
    'g' || 'г' => 'г',
    'l' || 'л' => 'л',
    'ml' || 'мл' => 'мл',
    _ => raw.trim(),
  };
}

String _formatNumeric(num value) {
  final whole = value % 1 == 0;
  return whole ? value.toInt().toString() : value.toStringAsFixed(1);
}

class QueueItem {
  const QueueItem({
    required this.name,
    required this.code,
    required this.age,
    required this.status,
    required this.accent,
    required this.icon,
  });

  final String name;
  final String code;
  final String age;
  final String status;
  final Color accent;
  final IconData icon;
}

class DeliveryRequestList {
  const DeliveryRequestList({
    required this.requests,
    required this.total,
  });

  final List<DeliveryRequestSummary> requests;
  final int total;
}

class AllocationList {
  const AllocationList({
    required this.allocations,
    required this.total,
  });

  final List<AllocationRecord> allocations;
  final int total;
}

class DeliveryRequestSummary {
  const DeliveryRequestSummary({
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
  final DeliveryPriority priority;
  final DeliveryRequestStatus status;
  final DateTime? arriveTill;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get priorityLabel => switch (priority) {
        DeliveryPriority.normal => 'Normal',
        DeliveryPriority.elevated => 'Elevated',
        DeliveryPriority.critical => 'Critical',
        DeliveryPriority.urgent => 'Urgent',
        DeliveryPriority.unknown => 'Unknown',
      };

  String get statusLabel => switch (status) {
        DeliveryRequestStatus.pending => 'Pending',
        DeliveryRequestStatus.allocated => 'Allocated',
        DeliveryRequestStatus.inTransit => 'In Transit',
        DeliveryRequestStatus.delivered => 'Delivered',
        DeliveryRequestStatus.cancelled => 'Cancelled',
        DeliveryRequestStatus.unknown => 'Unknown',
      };
}

class DeliveryRequestDetail {
  const DeliveryRequestDetail({
    required this.request,
    required this.items,
    required this.allocations,
  });

  final DeliveryRequestSummary request;
  final List<DeliveryRequestItem> items;
  final List<AllocationRecord> allocations;
}

class DeliveryRequestItem {
  const DeliveryRequestItem({
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
}

class AllocationRecord {
  const AllocationRecord({
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
  final AllocationStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get statusLabel => switch (status) {
        AllocationStatus.planned => 'Planned',
        AllocationStatus.approved => 'Approved',
        AllocationStatus.inTransit => 'In Transit',
        AllocationStatus.delivered => 'Delivered',
        AllocationStatus.cancelled => 'Cancelled',
        AllocationStatus.unknown => 'Unknown',
      };
}

class DemandReadingFeed {
  const DemandReadingFeed({
    required this.readings,
    required this.total,
  });

  final List<DemandReadingRecord> readings;
  final int total;
}

class DemandReadingRecord {
  const DemandReadingRecord({
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
  final DemandReadingSource source;
  final DateTime? recordedAt;
  final DateTime? createdAt;

  String get sourceLabel => switch (source) {
        DemandReadingSource.manual => 'Manual',
        DemandReadingSource.sensor => 'Sensor',
        DemandReadingSource.predicted => 'Predicted',
        DemandReadingSource.unknown => 'Unknown',
      };
}

class RebalancingProposalDetail {
  const RebalancingProposalDetail({
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
  final ProposalStatus status;
  final num confidence;
  final String urgency;
  final List<RebalancingTransfer> transfers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get statusLabel => switch (status) {
        ProposalStatus.pending => 'Pending',
        ProposalStatus.approved => 'Approved',
        ProposalStatus.dismissed => 'Dismissed',
        ProposalStatus.unknown => 'Unknown',
      };
}

class RebalancingTransfer {
  const RebalancingTransfer({
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
}

class NearestStockResult {
  const NearestStockResult({
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
}
