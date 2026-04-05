import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({
    super.key,
    required this.overview,
    required this.onBack,
    required this.onItemTap,
  });

  final InventoryOverview overview;
  final VoidCallback onBack;
  final ValueChanged<InventoryItem> onItemTap;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  static const String _allCategory = 'All';

  String _selectedCategory = _allCategory;

  List<String> get _categories {
    final categories = widget.overview.items
        .map((item) => item.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return <String>[_allCategory, ...categories];
  }

  List<InventoryItem> get _visibleItems {
    final items = widget.overview.items.where((item) {
      return _selectedCategory == _allCategory ||
          item.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    items.sort((a, b) {
      final categoryCompare =
          a.category.toLowerCase().compareTo(b.category.toLowerCase());
      if (categoryCompare != 0) {
        return categoryCompare;
      }
      return a.resourceName.toLowerCase().compareTo(b.resourceName.toLowerCase());
    });

    return items;
  }

  String _categoryLabel(String raw) {
    if (raw == _allCategory) {
      return raw;
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Uncategorized';
    }

    final words = trimmed.split(RegExp(r'[\s_-]+'));
    return words
        .where((word) => word.isNotEmpty)
        .map((word) {
          if (word.length == 1) {
            return word.toUpperCase();
          }
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleItems = _visibleItems;
    final criticalCount = visibleItems
        .where((item) => item.health == InventoryHealth.critical)
        .length;
    final lowCount = visibleItems
        .where((item) => item.health == InventoryHealth.low)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
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
          const SizedBox(height: 4),
          Text(
            'Warehouse ${widget.overview.locationLabel} • Live sync',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = category == _selectedCategory;
                return ChoiceChip(
                  selected: selected,
                  label: Text(_categoryLabel(category)),
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  side: const BorderSide(color: AppColors.stroke),
                  backgroundColor: AppColors.panel,
                  selectedColor: AppColors.warmGold,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: selected ? AppColors.canvas : AppColors.creamText,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DetailStatCard(
                  label: 'Visible',
                  value:
                      '${visibleItems.length}/${widget.overview.items.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DetailStatCard(
                  label: 'Low',
                  value: lowCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DetailStatCard(
                  label: 'Critical',
                  value: criticalCount.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'RESOURCES',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: visibleItems.isEmpty
                ? const PanelCard(
                    child: Text('No resources found for current filters.'),
                  )
                : ListView.builder(
                    itemCount: visibleItems.length,
                    itemBuilder: (context, index) {
                      final item = visibleItems[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == visibleItems.length - 1 ? 0 : 12,
                        ),
                        child: _InventoryItemCard(
                          item: item,
                          onTap: () => widget.onItemTap(item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({
    required this.item,
    required this.onTap,
  });

  final InventoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(item.health);
    final borderColor = _borderColor(item.health);
    final cardColor = _cardColor(item.health);
    final packageSize = item.packageSizeLabel;
    final approximateBaseAmount = item.approximateBaseAmountLabel;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              width: 62,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.resourceName,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCategory(item.category),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill(
                  label: item.healthLabel.toUpperCase(),
                  color: statusColor,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                  icon: Icons.inventory_2_outlined,
                  label: 'Qty',
                  value: item.quantityValueLabel,
                ),
                _InfoPill(
                  icon: Icons.straighten_rounded,
                  label: 'Unit',
                  value: item.normalizedUnitLabel,
                ),
                _InfoPill(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: item.locationLabel,
                ),
                if (packageSize != null)
                  _InfoPill(
                    icon: Icons.scale_rounded,
                    label: 'Pack size',
                    value: packageSize,
                  ),
                if (approximateBaseAmount != null)
                  _InfoPill(
                    icon: Icons.calculate_outlined,
                    label: 'Approx total',
                    value: '~$approximateBaseAmount',
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: AppColors.canvas.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Row(
                children: [
                  Text(
                    'View details',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.creamText,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.softText,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(InventoryHealth health) {
    return switch (health) {
      InventoryHealth.healthy => AppColors.greenOk,
      InventoryHealth.low => AppColors.amberWarn,
      InventoryHealth.critical => AppColors.redAlert,
    };
  }

  Color _cardColor(InventoryHealth health) {
    return switch (health) {
      InventoryHealth.healthy =>
        Color.lerp(AppColors.panel, const Color(0xFF43310D), 0.45)!,
      InventoryHealth.low =>
        Color.lerp(AppColors.panel, const Color(0xFF4A3409), 0.52)!,
      InventoryHealth.critical =>
        Color.lerp(AppColors.panel, const Color(0xFF4B1E12), 0.55)!,
    };
  }

  Color _borderColor(InventoryHealth health) {
    return switch (health) {
      InventoryHealth.healthy =>
        Color.lerp(AppColors.stroke, AppColors.greenOk, 0.45)!,
      InventoryHealth.low =>
        Color.lerp(AppColors.stroke, AppColors.amberWarn, 0.45)!,
      InventoryHealth.critical =>
        Color.lerp(AppColors.stroke, AppColors.redAlert, 0.45)!,
    };
  }

  String _formatCategory(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Uncategorized';
    }

    final words = trimmed.split(RegExp(r'[\s_-]+'));
    return words
        .where((word) => word.isNotEmpty)
        .map((word) {
          if (word.length == 1) {
            return word.toUpperCase();
          }
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.warmGold),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.creamText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
