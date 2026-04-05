import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({
    super.key,
    required this.resource,
    required this.actorRole,
    required this.returnLabel,
    required this.onBack,
    required this.onCreateRequest,
    required this.onConfirm,
  });

  final ResourceRecord resource;
  final UserRole actorRole;
  final String returnLabel;
  final VoidCallback onBack;
  final VoidCallback onCreateRequest;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final healthColor = _healthColor(resource.health);
    final canCreateRequest =
        actorRole == UserRole.worker || actorRole == UserRole.dispatcher;

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
                  'RESOURCE DETAILS',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                PanelCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RESOURCE',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.softText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  resource.name,
                                  style: theme.textTheme.titleLarge,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Updated ${resource.lastUpdatedLabel}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusPill(
                            label: resource.healthLabel.toUpperCase(),
                            color: healthColor,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ID ${resource.resourceId}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CURRENT STOCK',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.softText,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                PanelCard(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Quantity',
                              value: resource.quantityValueLabel,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricTile(
                              label: 'Unit',
                              value: resource.normalizedUnitLabel,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Category',
                              value: _formatCategory(resource.category),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricTile(
                              label: 'Location',
                              value: resource.location,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ACTIVITY',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.softText,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                PanelCard(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      _ActivityRow(
                        icon: Icons.sync_rounded,
                        title: 'Inventory snapshot synchronized',
                        subtitle: resource.lastUpdatedLabel,
                      ),
                      const SizedBox(height: 8),
                      _ActivityRow(
                        icon: Icons.inventory_2_outlined,
                        title: 'Current quantity registered',
                        subtitle:
                            '${resource.quantityValueLabel} ${resource.normalizedUnitLabel}',
                      ),
                      const SizedBox(height: 8),
                      _ActivityRow(
                        icon: Icons.warning_amber_rounded,
                        title: 'Current stock health',
                        subtitle: resource.healthLabel,
                        accent: healthColor,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (canCreateRequest)
                  OutlineActionButton(
                    label: 'Create Request',
                    icon: Icons.add_task_rounded,
                    onTap: onCreateRequest,
                  )
                else
                  Text(
                    'Request creation is available only for worker and dispatcher accounts.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.softText,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          PrimaryActionButton(
            label: returnLabel,
            icon: Icons.arrow_back_rounded,
            onPressed: onConfirm,
          ),
        ],
      ),
    );
  }

  Color _healthColor(InventoryHealth health) {
    return switch (health) {
      InventoryHealth.healthy => AppColors.greenOk,
      InventoryHealth.low => AppColors.amberWarn,
      InventoryHealth.critical => AppColors.redAlert,
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.creamText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent = AppColors.warmGold,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: accent),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
