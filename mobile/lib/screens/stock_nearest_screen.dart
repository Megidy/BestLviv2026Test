import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class StockNearestScreen extends StatelessWidget {
  const StockNearestScreen({
    super.key,
    required this.resourceIdController,
    required this.pointIdController,
    required this.quantityController,
    required this.results,
    required this.isBusy,
    this.errorMessage,
    required this.onBack,
    required this.onLookup,
  });

  final TextEditingController resourceIdController;
  final TextEditingController pointIdController;
  final TextEditingController quantityController;
  final List<NearestStockResult> results;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onLookup;

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
                  'NEAREST STOCK',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              IconButton(
                onPressed: onLookup,
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
                  'LOOKUP',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Find closest warehouses with available surplus for a resource.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TerminalField(
                  label: 'Resource ID',
                  controller: resourceIdController,
                ),
                const SizedBox(height: 10),
                TerminalField(
                  label: 'Destination Point ID',
                  controller: pointIdController,
                ),
                const SizedBox(height: 10),
                TerminalField(
                  label: 'Required Quantity (optional)',
                  controller: quantityController,
                ),
                const SizedBox(height: 12),
                OutlineActionButton(
                  label: 'Find Nearest Stock',
                  icon: Icons.travel_explore_rounded,
                  onTap: onLookup,
                  fillWidth: true,
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
                  label: 'MATCHES',
                  value: results.length.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (results.isEmpty)
            const PanelCard(
              child: Text('No nearest-stock candidates loaded yet.'),
            ),
          for (final result in results) ...[
            _NearestStockTile(result: result),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _NearestStockTile extends StatelessWidget {
  const _NearestStockTile({required this.result});

  final NearestStockResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PanelCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.warehouseLabel,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DetailLine(label: 'Warehouse ID', value: result.warehouseId.toString()),
          DetailLine(label: 'Resource ID', value: result.resourceId.toString()),
          DetailLine(
            label: 'Available',
            value: result.availableQuantity.toString(),
          ),
          DetailLine(
            label: 'Distance',
            value: result.distanceKm == null
                ? 'N/A'
                : '${result.distanceKm!.toStringAsFixed(1)} km',
          ),
          DetailLine(
            label: 'ETA',
            value: result.etaHours == null
                ? 'N/A'
                : '${result.etaHours!.toStringAsFixed(1)} h',
          ),
        ],
      ),
    );
  }
}
