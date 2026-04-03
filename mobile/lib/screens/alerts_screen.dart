import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({
    super.key,
    required this.alerts,
    required this.swaggerJsonUrl,
    required this.alertsEndpointUrl,
    required this.onBack,
  });

  final List<PredictiveAlert> alerts;
  final String swaggerJsonUrl;
  final String alertsEndpointUrl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final criticalCount = alerts
        .where((alert) => alert.severity == PredictiveAlertSeverity.critical)
        .length;
    final predictiveCount = alerts
        .where((alert) => alert.severity == PredictiveAlertSeverity.predictive)
        .length;
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
                  'ALERTS',
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
                          'LOGISYNC / CRITICAL FEED',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.softText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Alert Center',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Critical and predictive shortage notifications are prepared for /v1/predictive-alerts.',
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
                          label: 'OPEN ALERTS',
                          value: alerts.length.toString(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DetailStatCard(
                          label: 'CRITICAL',
                          value: criticalCount.toString(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DetailStatCard(
                          label: 'PREDICTIVE',
                          value: predictiveCount.toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ACTIVE FEED',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.softText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < alerts.length; i++) ...[
                    _AlertTile(alert: alerts[i]),
                    if (i != alerts.length - 1) const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'SWAGGER SOURCE',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.softText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PanelCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _SourceRow(
                          label: 'Spec',
                          value: swaggerJsonUrl,
                        ),
                        const SizedBox(height: 10),
                        _SourceRow(
                          label: 'Feed',
                          value: alertsEndpointUrl,
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

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final PredictiveAlert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (alert.severity) {
      PredictiveAlertSeverity.elevated => AppColors.amberWarn,
      PredictiveAlertSeverity.critical => AppColors.redAlert,
      PredictiveAlertSeverity.predictive => AppColors.greenOk,
    };

    return PanelCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              _iconFor(alert.severity),
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
                        alert.resourceName,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(
                      label: alert.severityLabel.toUpperCase(),
                      color: accent,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.locationLabel,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  alert.shortageNote,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.creamText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Alert #${alert.id} • ${alert.updatedLabel}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(PredictiveAlertSeverity severity) {
    return switch (severity) {
      PredictiveAlertSeverity.elevated => Icons.warning_amber_rounded,
      PredictiveAlertSeverity.critical => Icons.error_outline_rounded,
      PredictiveAlertSeverity.predictive => Icons.auto_graph_rounded,
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
