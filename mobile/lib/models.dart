import 'package:flutter/material.dart';

enum AppScreen {
  login,
  home,
  alerts,
  inventory,
  detail,
  demand,
  scanner,
  map,
  settings,
}

enum UrgencyLevel {
  normal,
  elevated,
  critical,
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
  });

  final int id;
  final String resourceName;
  final String locationLabel;
  final PredictiveAlertSeverity severity;
  final String shortageNote;
  final String updatedLabel;

  String get severityLabel => switch (severity) {
        PredictiveAlertSeverity.elevated => 'Elevated',
        PredictiveAlertSeverity.critical => 'Critical',
        PredictiveAlertSeverity.predictive => 'Predictive',
      };
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.resourceName,
    required this.category,
    required this.quantityLabel,
    required this.locationLabel,
    required this.health,
  });

  final int id;
  final String resourceName;
  final String category;
  final String quantityLabel;
  final String locationLabel;
  final InventoryHealth health;

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
    required this.name,
    required this.code,
    required this.manufacturer,
    required this.location,
    required this.currentStock,
    required this.threshold,
    required this.lastSync,
    required this.lastAudited,
    required this.receipt,
  });

  final String name;
  final String code;
  final String manufacturer;
  final String location;
  final String currentStock;
  final String threshold;
  final String lastSync;
  final String lastAudited;
  final String receipt;
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
