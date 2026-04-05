import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

List<QueueItem> buildQueueFromInventory({
  required InventoryOverview inventoryOverview,
  required List<PredictiveAlert> predictiveAlerts,
}) {
  final alertByResource = <String, PredictiveAlert>{
    for (final alert in predictiveAlerts) alert.resourceName: alert,
  };

  final items = List<InventoryItem>.from(inventoryOverview.items)
    ..sort((left, right) => _healthRank(left.health) - _healthRank(right.health));

  return items.take(5).map((item) {
    final alert = alertByResource[item.resourceName];
    final accent = switch (item.health) {
      InventoryHealth.healthy => AppColors.greenOk,
      InventoryHealth.low => AppColors.amberWarn,
      InventoryHealth.critical => AppColors.redAlert,
    };

    return QueueItem(
      name: item.resourceName,
      code: 'ID-${item.id} - ${item.quantityLabel}',
      age: alert?.updatedLabel ?? 'Live sync',
      status: item.healthLabel.toLowerCase(),
      accent: accent,
      icon: _iconForCategory(item.category),
    );
  }).toList();
}

int _healthRank(InventoryHealth health) {
  return switch (health) {
    InventoryHealth.critical => 0,
    InventoryHealth.low => 1,
    InventoryHealth.healthy => 2,
  };
}

IconData _iconForCategory(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('liquid') || normalized.contains('cool')) {
    return Icons.opacity_rounded;
  }
  if (normalized.contains('energy') || normalized.contains('cell')) {
    return Icons.battery_alert_rounded;
  }
  if (normalized.contains('hardware') || normalized.contains('fastener')) {
    return Icons.grid_view_rounded;
  }
  if (normalized.contains('construction')) {
    return Icons.construction_rounded;
  }
  return Icons.inventory_2_rounded;
}
