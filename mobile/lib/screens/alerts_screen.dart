import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

enum _AlertFilter {
  all,
  critical,
  elevated,
  predictive,
  review,
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({
    super.key,
    required this.alerts,
    required this.actorRole,
    required this.locationLabel,
    required this.isBusy,
    required this.onDismissAlert,
    required this.onOpenProposal,
    required this.onOpenMap,
    required this.onRefresh,
    required this.onBack,
  });

  final List<PredictiveAlert> alerts;
  final UserRole actorRole;
  final String locationLabel;
  final bool isBusy;
  final ValueChanged<PredictiveAlert> onDismissAlert;
  final ValueChanged<PredictiveAlert> onOpenProposal;
  final ValueChanged<PredictiveAlert> onOpenMap;
  final VoidCallback onRefresh;
  final VoidCallback onBack;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  _AlertFilter _selectedFilter = _AlertFilter.all;

  List<PredictiveAlert> get _visibleAlerts {
    final filtered = widget.alerts
        .where(_matchesFilter)
        .toList()
      ..sort(_compareAlerts);

    return filtered;
  }

  bool _matchesFilter(PredictiveAlert alert) {
    return switch (_selectedFilter) {
      _AlertFilter.all => true,
      _AlertFilter.critical =>
        alert.severity == PredictiveAlertSeverity.critical,
      _AlertFilter.elevated =>
        alert.severity == PredictiveAlertSeverity.elevated,
      _AlertFilter.predictive =>
        alert.severity == PredictiveAlertSeverity.predictive,
      _AlertFilter.review =>
        alert.proposalId != null && (alert.proposalId ?? 0) > 0,
    };
  }

  int _compareAlerts(PredictiveAlert a, PredictiveAlert b) {
    final severityCompare = _severityRank(
      a.severity,
    ).compareTo(_severityRank(b.severity));
    if (severityCompare != 0) {
      return severityCompare;
    }

    final aEta = a.predictedShortfallAt;
    final bEta = b.predictedShortfallAt;
    if (aEta != null && bEta != null) {
      return aEta.compareTo(bEta);
    }
    if (aEta != null) {
      return -1;
    }
    if (bEta != null) {
      return 1;
    }

    return a.id.compareTo(b.id);
  }

  int _severityRank(PredictiveAlertSeverity severity) {
    return switch (severity) {
      PredictiveAlertSeverity.critical => 0,
      PredictiveAlertSeverity.elevated => 1,
      PredictiveAlertSeverity.predictive => 2,
    };
  }

  bool _isDueSoon(PredictiveAlert alert) {
    final value = alert.predictedShortfallAt;
    if (value == null) {
      return false;
    }

    final delta = value.difference(DateTime.now());
    return delta.inMinutes >= 0 && delta.inHours <= 6;
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.worker => 'Worker',
      UserRole.dispatcher => 'Dispatcher',
      UserRole.admin => 'Admin',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allAlerts = widget.alerts;
    final visibleAlerts = _visibleAlerts;
    final canDismiss = widget.actorRole == UserRole.dispatcher;
    final canOpenProposal = widget.actorRole == UserRole.dispatcher;

    final criticalCount = allAlerts
        .where((alert) => alert.severity == PredictiveAlertSeverity.critical)
        .length;
    final reviewCount = allAlerts
        .where((alert) => alert.proposalId != null && (alert.proposalId ?? 0) > 0)
        .length;
    final dueSoonCount = allAlerts.where(_isDueSoon).length;

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
                  'ALERTS',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.isBusy ? null : widget.onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (widget.isBusy)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.warmGold,
                backgroundColor: AppColors.stroke,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            '${_roleLabel(widget.actorRole)} • Warehouse ${widget.locationLabel} • Live sync',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  count: allAlerts.length,
                  selected: _selectedFilter == _AlertFilter.all,
                  onTap: () => setState(() => _selectedFilter = _AlertFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Critical',
                  count: criticalCount,
                  selected: _selectedFilter == _AlertFilter.critical,
                  onTap: () =>
                      setState(() => _selectedFilter = _AlertFilter.critical),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Elevated',
                  count: allAlerts
                      .where(
                        (alert) =>
                            alert.severity == PredictiveAlertSeverity.elevated,
                      )
                      .length,
                  selected: _selectedFilter == _AlertFilter.elevated,
                  onTap: () =>
                      setState(() => _selectedFilter = _AlertFilter.elevated),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Predictive',
                  count: allAlerts
                      .where(
                        (alert) =>
                            alert.severity == PredictiveAlertSeverity.predictive,
                      )
                      .length,
                  selected: _selectedFilter == _AlertFilter.predictive,
                  onTap: () =>
                      setState(() => _selectedFilter = _AlertFilter.predictive),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Review',
                  count: reviewCount,
                  selected: _selectedFilter == _AlertFilter.review,
                  onTap: () => setState(() => _selectedFilter = _AlertFilter.review),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DetailStatCard(
                  label: 'Open',
                  value: allAlerts.length.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DetailStatCard(
                  label: 'Critical',
                  value: criticalCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DetailStatCard(
                  label: 'Due ≤6h',
                  value: dueSoonCount.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'ACTIVE FEED (${visibleAlerts.length})',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: visibleAlerts.isEmpty
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: _EmptyFeedCard(
                      selectedFilter: _selectedFilter,
                      onResetFilter: () {
                        setState(() {
                          _selectedFilter = _AlertFilter.all;
                        });
                      },
                    ),
                  )
                : ListView.builder(
                    itemCount: visibleAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = visibleAlerts[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == visibleAlerts.length - 1 ? 0 : 12,
                        ),
                        child: _AlertCard(
                          alert: alert,
                          isBusy: widget.isBusy,
                          canDismiss: canDismiss,
                          canOpenProposal: canOpenProposal,
                          onDismiss: () => widget.onDismissAlert(alert),
                          onOpenProposal: () => widget.onOpenProposal(alert),
                          onOpenMap: () => widget.onOpenMap(alert),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text('$label ($count)'),
      showCheckmark: false,
      onSelected: (_) => onTap(),
      side: const BorderSide(color: AppColors.stroke),
      backgroundColor: AppColors.panel,
      selectedColor: AppColors.warmGold,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.canvas : AppColors.creamText,
          ),
    );
  }
}

class _EmptyFeedCard extends StatelessWidget {
  const _EmptyFeedCard({
    required this.selectedFilter,
    required this.onResetFilter,
  });

  final _AlertFilter selectedFilter;
  final VoidCallback onResetFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAll = selectedFilter == _AlertFilter.all;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: PanelCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAll
                  ? 'No active alerts right now.'
                  : 'No active alerts for current filter.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.creamText,
              ),
            ),
            if (!isAll) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onResetFilter,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                  label: const Text('Show all alerts'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.isBusy,
    required this.canDismiss,
    required this.canOpenProposal,
    required this.onDismiss,
    required this.onOpenProposal,
    required this.onOpenMap,
  });

  final PredictiveAlert alert;
  final bool isBusy;
  final bool canDismiss;
  final bool canOpenProposal;
  final VoidCallback onDismiss;
  final VoidCallback onOpenProposal;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentColor(alert.severity);
    final cardColor = _cardColor(alert.severity);
    final borderColor = Color.lerp(AppColors.stroke, accent, 0.45)!;
    final hasProposal = alert.proposalId != null && (alert.proposalId ?? 0) > 0;
    final dispatcherOnlyLabel = hasProposal
        ? 'Proposal and dismiss: dispatcher-only'
        : 'Dismiss: dispatcher-only';

    return Ink(
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
            width: 68,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  alert.resourceName,
                  style: theme.textTheme.titleLarge,
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
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.creamText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Updated ${alert.updatedLabel}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Text(
            alert.shortageNote,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.creamText,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricPill(
                icon: Icons.timer_outlined,
                label: 'ETA',
                value: alert.etaLabel,
              ),
              _MetricPill(
                icon: Icons.analytics_outlined,
                label: 'Confidence',
                value: alert.confidenceLabel,
              ),
              _MetricPill(
                icon: Icons.tag_rounded,
                label: 'Alert',
                value: '#${alert.id}',
              ),
              if (hasProposal)
                _MetricPill(
                  icon: Icons.auto_graph_rounded,
                  label: 'Proposal',
                  value: '#${alert.proposalId}',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasProposal && canOpenProposal)
                _AlertActionButton(
                  label: 'Review Plan',
                  icon: Icons.playlist_add_check_circle_outlined,
                  accent: AppColors.warmGold,
                  onPressed: isBusy ? null : onOpenProposal,
                ),
              _AlertActionButton(
                label: 'Map',
                icon: Icons.map_outlined,
                accent: AppColors.creamText,
                onPressed: isBusy ? null : onOpenMap,
              ),
              if (canDismiss)
                _AlertActionButton(
                  label: 'Dismiss',
                  icon: Icons.close_rounded,
                  accent: AppColors.redAlert,
                  onPressed: isBusy ? null : onDismiss,
                ),
              if (!canDismiss)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.canvas.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: Text(
                    dispatcherOnlyLabel,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _accentColor(PredictiveAlertSeverity severity) {
    return switch (severity) {
      PredictiveAlertSeverity.elevated => AppColors.amberWarn,
      PredictiveAlertSeverity.critical => AppColors.redAlert,
      PredictiveAlertSeverity.predictive => AppColors.greenOk,
    };
  }

  Color _cardColor(PredictiveAlertSeverity severity) {
    return switch (severity) {
      PredictiveAlertSeverity.elevated =>
        Color.lerp(AppColors.panel, const Color(0xFF4A3409), 0.52)!,
      PredictiveAlertSeverity.critical =>
        Color.lerp(AppColors.panel, const Color(0xFF4A1B12), 0.58)!,
      PredictiveAlertSeverity.predictive =>
        Color.lerp(AppColors.panel, const Color(0xFF2F2A10), 0.52)!,
    };
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
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
        color: AppColors.canvas.withValues(alpha: 0.62),
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

class _AlertActionButton extends StatelessWidget {
  const _AlertActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: disabled ? AppColors.softText : accent,
        side: BorderSide(
          color: disabled
              ? AppColors.stroke
              : accent.withValues(alpha: 0.42),
        ),
        backgroundColor: AppColors.canvas.withValues(alpha: 0.42),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: disabled
                  ? AppColors.softText
                  : accent == AppColors.warmGold
                      ? AppColors.creamText
                      : accent,
            ),
      ),
    );
  }
}
