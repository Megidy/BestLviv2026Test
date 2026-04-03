import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.queue,
    required this.navIndex,
    required this.onQuickScan,
    required this.onQueueTap,
    required this.onNavigate,
  });

  final List<QueueItem> queue;
  final int navIndex;
  final VoidCallback onQuickScan;
  final VoidCallback onQueueTap;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                            'LOGISYNC / WH-04',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.softText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Central Terminal',
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
                    const CircleBadge(label: 'JD'),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Expanded(child: MetricCard(label: 'Active', value: '24')),
                    SizedBox(width: 10),
                    Expanded(child: MetricCard(label: 'Pending', value: '08')),
                    SizedBox(width: 10),
                    Expanded(
                      child: MetricCard(
                        label: 'Critical',
                        value: '03',
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
                for (final item in queue) ...[
                  QueueCard(item: item, onTap: onQueueTap),
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
