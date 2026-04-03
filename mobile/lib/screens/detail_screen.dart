import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({
    super.key,
    required this.resource,
    required this.onBack,
    required this.onUpdate,
    required this.onConfirm,
  });

  final ResourceRecord resource;
  final VoidCallback onBack;
  final VoidCallback onUpdate;
  final VoidCallback onConfirm;

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
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PanelCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESOURCE ID: RE-RE2911',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.softText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        resource.name,
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    const StatusPill(
                      label: 'CRITICAL',
                      color: AppColors.redAlert,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'USAGE TREND',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          const SizedBox(height: 8),
          const PanelCard(
            padding: EdgeInsets.all(0),
            child: SizedBox(
              height: 138,
              child: UsageTrendChart(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DetailStatCard(
                  label: 'CURRENT STOCK',
                  value: resource.currentStock,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DetailStatCard(
                  label: 'RECEIPT DT',
                  value: resource.receipt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'SPECIFICATIONS',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          const SizedBox(height: 8),
          PanelCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: [
                SpecRow(label: 'Manufacturer', value: resource.manufacturer),
                SpecRow(label: 'Location', value: resource.location),
                SpecRow(label: 'Last Audited', value: resource.lastAudited),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'QUICK ACTIONS',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlineActionButton(
                  label: 'UPDATE',
                  icon: Icons.edit_rounded,
                  onTap: onUpdate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlineActionButton(
                  label: 'URGENT',
                  icon: Icons.priority_high_rounded,
                  accent: AppColors.redAlert,
                  onTap: onUpdate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlineActionButton(
                  label: 'REJECT',
                  icon: Icons.warning_amber_rounded,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlineActionButton(
                  label: 'MOVE',
                  icon: Icons.open_with_rounded,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryActionButton(
            label: 'Confirm Delivery Receipt',
            icon: Icons.verified_rounded,
            onPressed: onConfirm,
          ),
        ],
      ),
    );
  }
}
