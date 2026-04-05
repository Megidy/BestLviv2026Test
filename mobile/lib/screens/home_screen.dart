import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.queue,
    required this.navIndex,
    required this.locationLabel,
    required this.locationTitle,
    required this.accountLabel,
    required this.isOnline,
    required this.lastSyncLabel,
    required this.pendingMutationCount,
    required this.isSyncingQueue,
    required this.alertCount,
    required this.activeCount,
    required this.pendingCount,
    required this.criticalCount,
    required this.onQuickScan,
    required this.onRequestsTap,
    required this.onDemandReadingsTap,
    required this.onStockNearestTap,
    required this.onAlertsTap,
    required this.onAccountTap,
    required this.onQueueTap,
    required this.onNavigate,
  });

  final List<QueueItem> queue;
  final int navIndex;
  final String locationLabel;
  final String locationTitle;
  final String accountLabel;
  final bool isOnline;
  final String? lastSyncLabel;
  final int pendingMutationCount;
  final bool isSyncingQueue;
  final int alertCount;
  final int activeCount;
  final int pendingCount;
  final int criticalCount;
  final VoidCallback onQuickScan;
  final VoidCallback onRequestsTap;
  final VoidCallback onDemandReadingsTap;
  final VoidCallback onStockNearestTap;
  final VoidCallback onAlertsTap;
  final VoidCallback onAccountTap;
  final ValueChanged<QueueItem> onQueueTap;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showAlertsButton = alertCount > 0;
    final alertBadgeLabel = alertCount > 9 ? '9+' : alertCount.toString();
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOGISYNC / $locationLabel',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.softText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            locationTitle,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: 6),
                          StatusPill(
                            label: isOnline ? 'SYSTEM ONLINE' : 'OFFLINE MODE',
                            color: isOnline ? AppColors.greenOk : AppColors.amberWarn,
                          ),
                          if (lastSyncLabel != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              lastSyncLabel!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.softText,
                              ),
                            ),
                          ],
                          if (pendingMutationCount > 0) ...[
                            const SizedBox(height: 6),
                            Text(
                              isSyncingQueue
                                  ? 'Sync queue: $pendingMutationCount (syncing...)'
                                  : 'Sync queue: $pendingMutationCount (waiting for connection)',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.warmGold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (showAlertsButton)
                          _AlertsIconButton(
                            countLabel: alertBadgeLabel,
                            onTap: onAlertsTap,
                          ),
                        if (showAlertsButton) const SizedBox(width: 10),
                        CircleBadge(
                          label: accountLabel,
                          onTap: onAccountTap,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        label: 'Active',
                        value: activeCount.toString(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MetricCard(
                        label: 'Pending',
                        value: pendingCount.toString(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MetricCard(
                        label: 'Critical',
                        value: criticalCount.toString(),
                        accent: AppColors.redAlert,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ActionBanner(
                  title: 'Quick Scan',
                  subtitle: 'Ready for next resource',
                  leadingIcon: Icons.qr_code_scanner_rounded,
                  onTap: onQuickScan,
                ),
                const SizedBox(height: 10),
                ActionBanner(
                  title: 'Delivery Requests',
                  subtitle: 'Open list and manage lifecycle actions',
                  leadingIcon: Icons.local_shipping_outlined,
                  onTap: onRequestsTap,
                ),
                const SizedBox(height: 10),
                ActionBanner(
                  title: 'Demand Readings',
                  subtitle: 'Feed AI with manual demand signals',
                  leadingIcon: Icons.insights_outlined,
                  onTap: onDemandReadingsTap,
                ),
                const SizedBox(height: 10),
                ActionBanner(
                  title: 'Nearest Stock',
                  subtitle: 'Find closest warehouses with surplus stock',
                  leadingIcon: Icons.route_rounded,
                  onTap: onStockNearestTap,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      'Priority Queue',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      'VIEW ALL',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.creamText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (queue.isEmpty)
                  const PanelCard(
                    child: Text('No priority items loaded from the API yet.'),
                  ),
                for (final item in queue) ...[
                  QueueCard(item: item, onTap: () => onQueueTap(item)),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
        TerminalBottomBar(
          currentIndex: navIndex,
          onTap: onNavigate,
        ),
      ],
    );
  }
}

class _AlertsIconButton extends StatelessWidget {
  const _AlertsIconButton({
    required this.countLabel,
    required this.onTap,
  });

  final String countLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SmallSquareButton(
          icon: Icons.notifications_active_outlined,
          onTap: onTap,
        ),
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18),
            height: 18,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: AppColors.redAlert,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.canvas,
                width: 1.2,
              ),
            ),
            child: Center(
              child: Text(
                countLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.creamText,
                      fontSize: 10,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
