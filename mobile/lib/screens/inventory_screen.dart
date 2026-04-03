import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({
    super.key,
    required this.overview,
    required this.swaggerJsonUrl,
    required this.inventoryEndpointUrl,
    required this.onBack,
  });

  final InventoryOverview overview;
  final String swaggerJsonUrl;
  final String inventoryEndpointUrl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final swaggerHost = Uri.tryParse(swaggerJsonUrl)?.host;
    final inventoryPath =
        Uri.tryParse(inventoryEndpointUrl)?.path ?? inventoryEndpointUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              Expanded(
                child: Text(
                  'INVENTORY',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PanelCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOGISYNC / STOCK INDEX',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.softText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Inventory Terminal',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Inventory feed prepared for location-based data from the shared swagger source.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DetailStatCard(
                          label: 'LOCATION',
                          value: overview.locationLabel,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DetailStatCard(
                          label: 'TOTAL UNITS',
                          value: overview.totalUnits.toString(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DetailStatCard(
                          label: 'LOW STOCK',
                          value: overview.lowStockCount.toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'RESOURCE INDEX',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.softText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < overview.items.length; i++) ...[
                    _InventoryTile(item: overview.items[i]),
                    if (i != overview.items.length - 1)
                      const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'API SOURCE',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.softText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PanelCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _SourceRow(label: 'Spec', value: swaggerJsonUrl),
                        const SizedBox(height: 10),
                        _SourceRow(label: 'Feed', value: inventoryPath),
                        const SizedBox(height: 10),
                        _SourceRow(
                          label: 'Host',
                          value: swaggerHost ?? 'shared swagger config',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (item.health) {
      InventoryHealth.healthy => AppColors.greenOk,
      InventoryHealth.low => AppColors.amberWarn,
      InventoryHealth.critical => AppColors.redAlert,
    };

    return PanelCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              _iconFor(item.health),
              size: 18,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.resourceName,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(
                      label: item.healthLabel.toUpperCase(),
                      color: accent,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.category,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  item.quantityLabel,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.creamText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.locationLabel,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(InventoryHealth health) {
    return switch (health) {
      InventoryHealth.healthy => Icons.inventory_2_outlined,
      InventoryHealth.low => Icons.warning_amber_rounded,
      InventoryHealth.critical => Icons.error_outline_rounded,
    };
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.softText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.creamText,
          ),
        ),
      ],
    );
  }
}
