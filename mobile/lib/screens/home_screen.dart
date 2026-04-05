import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.actorRole,
    required this.queue,
    required this.navIndex,
    required this.locationLabel,
    required this.locationTitle,
    required this.accountLabel,
    required this.activeCount,
    required this.pendingCount,
    required this.criticalCount,
    required this.onQuickScan,
    required this.onRequestsTap,
    required this.onDemandReadingsTap,
    required this.onRebalancingTap,
    required this.onStockNearestTap,
    required this.onAlertsTap,
    required this.onAccountTap,
    required this.onQueueTap,
    required this.onNavigate,
  });

  final UserRole actorRole;
  final List<QueueItem> queue;
  final int navIndex;
  final String locationLabel;
  final String locationTitle;
  final String accountLabel;
  final int activeCount;
  final int pendingCount;
  final int criticalCount;
  final VoidCallback onQuickScan;
  final VoidCallback onRequestsTap;
  final VoidCallback onDemandReadingsTap;
  final VoidCallback onRebalancingTap;
  final VoidCallback onStockNearestTap;
  final VoidCallback onAlertsTap;
  final VoidCallback onAccountTap;
  final ValueChanged<QueueItem> onQueueTap;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canUseRebalancing = actorRole == UserRole.dispatcher;
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
                          const StatusPill(
                            label: 'SYSTEM ONLINE',
                            color: AppColors.greenOk,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        SmallSquareButton(
                          icon: Icons.notifications_active_outlined,
                          onTap: onAlertsTap,
                        ),
                        const SizedBox(width: 10),
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
                if (canUseRebalancing) ...[
                  const SizedBox(height: 10),
                  ActionBanner(
                    title: 'Rebalancing Proposals',
                    subtitle: 'Review and apply AI redistribution plans',
                    leadingIcon: Icons.auto_graph_rounded,
                    onTap: onRebalancingTap,
                  ),
                ],
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
