import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DemandScreen extends StatelessWidget {
  const DemandScreen({
    super.key,
    required this.resource,
    required this.urgency,
    required this.requestQuantity,
    required this.reasonController,
    required this.onBack,
    required this.onConfirm,
    required this.onUrgencyChange,
    required this.onAddQuantity,
  });

  final ResourceRecord resource;
  final UrgencyLevel urgency;
  final int requestQuantity;
  final TextEditingController reasonController;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  final ValueChanged<UrgencyLevel> onUrgencyChange;
  final ValueChanged<int> onAddQuantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FillViewportScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.close_rounded),
              ),
              Expanded(
                child: Text(
                  'UPDATE DEMAND',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 12),
          PanelCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.redAlert.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: AppColors.redAlert,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resource.name,
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            resource.code,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DetailLine(label: 'Current Stock', value: resource.currentStock),
                DetailLine(label: 'Min. Threshold', value: resource.threshold),
                DetailLine(label: 'Last Sync', value: resource.lastSync),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SET URGENCY LEVEL',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: UrgencyCard(
                  label: 'NORMAL',
                  icon: Icons.check_circle_outline_rounded,
                  selected: urgency == UrgencyLevel.normal,
                  color: AppColors.greenOk,
                  onTap: () => onUrgencyChange(UrgencyLevel.normal),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: UrgencyCard(
                  label: 'ELEVATED',
                  icon: Icons.warning_amber_rounded,
                  selected: urgency == UrgencyLevel.elevated,
                  color: AppColors.amberWarn,
                  onTap: () => onUrgencyChange(UrgencyLevel.elevated),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: UrgencyCard(
                  label: 'CRITICAL',
                  icon: Icons.error_outline_rounded,
                  selected: urgency == UrgencyLevel.critical,
                  color: AppColors.redAlert,
                  onTap: () => onUrgencyChange(UrgencyLevel.critical),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'REQUEST QUANTITY',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PanelCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$requestQuantity',
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        'Units to be dispatched',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CompactActionButton(
                label: '+10',
                onTap: () => onAddQuantity(10),
              ),
              const SizedBox(width: 10),
              CompactActionButton(
                label: '+50',
                onTap: () => onAddQuantity(50),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'INTERNAL NOTES',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          const SizedBox(height: 8),
          TerminalField(
            label: 'Reason',
            controller: reasonController,
            maxLines: 2,
          ),
          const SizedBox(height: 18),
          PrimaryActionButton(
            label: 'Confirm Update',
            icon: Icons.check_rounded,
            onPressed: onConfirm,
          ),
          const SizedBox(height: 10),
          OutlineActionButton(
            label: 'Cancel',
            icon: Icons.close_rounded,
            onTap: onBack,
            fillWidth: true,
          ),
        ],
      ),
    );
  }
}
