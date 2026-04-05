import '../models.dart';

ResourceRecord buildResourceRecordFromItem({
  required InventoryItem item,
  required String lastUpdatedLabel,
}) {
  return ResourceRecord(
    resourceId: item.resourceId,
    name: item.resourceName,
    category: item.category,
    location: item.locationLabel,
    quantityValue: item.quantityValue,
    unitLabel: item.unitLabel,
    health: item.health,
    lastUpdatedLabel: lastUpdatedLabel,
  );
}

const ResourceRecord fallbackResourceRecord = ResourceRecord(
  resourceId: 0,
  name: 'Resource unavailable',
  category: 'Unknown',
  location: 'Unknown location',
  quantityValue: 0,
  unitLabel: 'units',
  health: InventoryHealth.low,
  lastUpdatedLabel: 'Not synced',
);
