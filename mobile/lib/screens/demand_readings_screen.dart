import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DemandReadingsScreen extends StatelessWidget {
  const DemandReadingsScreen({
    super.key,
    required this.pointIdController,
    required this.resourceIdController,
    required this.quantityController,
    required this.recordedAtController,
    required this.readings,
    required this.total,
    required this.isBusy,
    this.errorMessage,
    required this.onBack,
    required this.onRefresh,
    required this.onSubmit,
  });

  final TextEditingController pointIdController;
  final TextEditingController resourceIdController;
  final TextEditingController quantityController;
  final TextEditingController recordedAtController;
  final List<DemandReadingRecord> readings;
  final int total;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onSubmit;

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
                  'DEMAND READINGS',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
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
                  'FEED THE AI',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Submit a demand signal and refresh history for the point.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TerminalField(
                  label: 'Point ID',
                  controller: pointIdController,
                ),
                const SizedBox(height: 10),
                TerminalField(
                  label: 'Resource ID',
                  controller: resourceIdController,
                ),
                const SizedBox(height: 10),
                TerminalField(
                  label: 'Quantity',
                  controller: quantityController,
                ),
                const SizedBox(height: 10),
                TerminalField(
                  label: 'Recorded At (optional ISO)',
                  controller: recordedAtController,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlineActionButton(
                        label: 'Refresh History',
                        icon: Icons.history_rounded,
                        onTap: onRefresh,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlineActionButton(
                        label: 'Submit Reading',
                        icon: Icons.send_rounded,
                        onTap: onSubmit,
                      ),
                    ),
                  ],
                ),
                if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.redAlert,
                    ),
                  ),
                ],
                if (isBusy) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.warmGold,
                    backgroundColor: AppColors.stroke,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DetailStatCard(
                  label: 'HISTORY',
                  value: total.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (readings.isEmpty)
            const PanelCard(
              child: Text('No demand readings loaded for this point yet.'),
            ),
          for (final reading in readings) ...[
            _DemandReadingTile(reading: reading),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _DemandReadingTile extends StatelessWidget {
  const _DemandReadingTile({required this.reading});

  final DemandReadingRecord reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PanelCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading #${reading.id}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DetailLine(label: 'Point ID', value: reading.pointId.toString()),
          DetailLine(label: 'Resource ID', value: reading.resourceId.toString()),
          DetailLine(label: 'Quantity', value: reading.quantity.toString()),
          DetailLine(label: 'Source', value: reading.sourceLabel),
        ],
      ),
    );
  }
}
