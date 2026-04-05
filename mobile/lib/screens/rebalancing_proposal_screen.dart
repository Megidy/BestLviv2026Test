import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class RebalancingProposalScreen extends StatelessWidget {
  const RebalancingProposalScreen({
    super.key,
    required this.proposalIdController,
    required this.proposal,
    required this.actorRole,
    required this.isBusy,
    this.errorMessage,
    this.statusMessage,
    required this.onBack,
    required this.onLoad,
    required this.onApprove,
    required this.onDismiss,
  });

  final TextEditingController proposalIdController;
  final RebalancingProposalDetail? proposal;
  final UserRole actorRole;
  final bool isBusy;
  final String? errorMessage;
  final String? statusMessage;
  final VoidCallback onBack;
  final VoidCallback onLoad;
  final VoidCallback onApprove;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeProposal = proposal;
    final canAccess = actorRole == UserRole.dispatcher;
    final canModerate =
        activeProposal != null &&
        activeProposal.status == ProposalStatus.pending &&
        actorRole == UserRole.dispatcher;

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
                  'REBALANCING',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              IconButton(
                onPressed: isBusy ? null : onLoad,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (isBusy)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.warmGold,
                backgroundColor: AppColors.stroke,
              ),
            ),
          if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
            _MessageBanner(
              icon: Icons.error_outline_rounded,
              message: errorMessage!,
              color: AppColors.redAlert,
            ),
            const SizedBox(height: 10),
          ],
          if (statusMessage != null && statusMessage!.trim().isNotEmpty) ...[
            _MessageBanner(
              icon: Icons.check_circle_outline_rounded,
              message: statusMessage!,
              color: AppColors.greenOk,
            ),
            const SizedBox(height: 10),
          ],
          if (!canAccess)
            const PanelCard(
              child: Text(
                'Rebalancing proposal tools are available only for dispatcher accounts in mobile app.',
              ),
            )
          else if (activeProposal == null)
            _LoadProposalCard(
              proposalIdController: proposalIdController,
              isBusy: isBusy,
              onLoad: onLoad,
              title: 'Load Proposal',
              subtitle:
                  'Enter proposal ID to open AI plan and review transfers.',
            )
          else ...[
            _ProposalSummaryCard(
              proposal: activeProposal,
              canModerate: canModerate,
              isBusy: isBusy,
              onApprove: onApprove,
              onDismiss: onDismiss,
            ),
            const SizedBox(height: 12),
            _LoadProposalCard(
              proposalIdController: proposalIdController,
              isBusy: isBusy,
              onLoad: onLoad,
              title: 'Load Another Proposal',
              subtitle: 'Switch to a different proposal by ID.',
              compact: true,
            ),
            const SizedBox(height: 12),
            Text(
              'TRANSFERS (${activeProposal.transfers.length})',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.softText,
              ),
            ),
            const SizedBox(height: 8),
            if (activeProposal.transfers.isEmpty)
              const PanelCard(
                child: Text('No transfers attached to this proposal yet.'),
              )
            else
              for (var i = 0; i < activeProposal.transfers.length; i++) ...[
                _TransferCard(transfer: activeProposal.transfers[i]),
                if (i != activeProposal.transfers.length - 1)
                  const SizedBox(height: 10),
              ],
          ],
        ],
      ),
    );
  }
}

class _LoadProposalCard extends StatelessWidget {
  const _LoadProposalCard({
    required this.proposalIdController,
    required this.isBusy,
    required this.onLoad,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final TextEditingController proposalIdController;
  final bool isBusy;
  final VoidCallback onLoad;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PanelCard(
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          TerminalField(
            label: 'Proposal ID',
            controller: proposalIdController,
            prefixIcon: Icons.pin_outlined,
          ),
          const SizedBox(height: 10),
          OutlineActionButton(
            label: 'Load Proposal',
            icon: Icons.search_rounded,
            onTap: isBusy ? () {} : onLoad,
            fillWidth: true,
          ),
        ],
      ),
    );
  }
}

class _ProposalSummaryCard extends StatelessWidget {
  const _ProposalSummaryCard({
    required this.proposal,
    required this.canModerate,
    required this.isBusy,
    required this.onApprove,
    required this.onDismiss,
  });

  final RebalancingProposalDetail proposal;
  final bool canModerate;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(proposal.status);

    return PanelCard(
      padding: const EdgeInsets.all(14),
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
                      'PROPOSAL #${proposal.id}',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Resource #${proposal.resourceId} • Target point #${proposal.targetPointId}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: proposal.statusLabel.toUpperCase(),
                color: statusColor,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(
                icon: Icons.analytics_outlined,
                label: 'Confidence',
                value: '${(proposal.confidence * 100).round()}%',
              ),
              _SummaryPill(
                icon: Icons.priority_high_rounded,
                label: 'Urgency',
                value: _formatUrgency(proposal.urgency),
              ),
              _SummaryPill(
                icon: Icons.local_shipping_outlined,
                label: 'Transfers',
                value: proposal.transfers.length.toString(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (canModerate) ...[
            Row(
              children: [
                Expanded(
                  child: OutlineActionButton(
                    label: 'Approve Plan',
                    icon: Icons.check_circle_outline_rounded,
                    onTap: isBusy ? () {} : onApprove,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlineActionButton(
                    label: 'Dismiss',
                    icon: Icons.cancel_outlined,
                    accent: AppColors.redAlert,
                    onTap: isBusy ? () {} : onDismiss,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.canvas.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Text(
                proposal.status == ProposalStatus.pending
                    ? 'Approve/Dismiss is available for dispatcher on pending proposals.'
                    : 'Proposal is already finalized.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(ProposalStatus status) {
    return switch (status) {
      ProposalStatus.pending => AppColors.amberWarn,
      ProposalStatus.approved => AppColors.greenOk,
      ProposalStatus.dismissed => AppColors.redAlert,
      ProposalStatus.unknown => AppColors.softText,
    };
  }

  String _formatUrgency(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Unknown';
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

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
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
        color: AppColors.canvas.withValues(alpha: 0.55),
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

class _TransferCard extends StatelessWidget {
  const _TransferCard({required this.transfer});

  final RebalancingTransfer transfer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final etaLabel = _formatEta(transfer.estimatedArrivalHours);

    return PanelCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Transfer #${transfer.id}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              StatusPill(
                label: etaLabel == 'Now' ? 'NOW' : 'ETA $etaLabel',
                color: etaLabel == 'Now' ? AppColors.redAlert : AppColors.warmGold,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          DetailLine(
            label: 'From warehouse',
            value: _warehouseLabel(transfer.fromWarehouseId),
          ),
          DetailLine(
            label: 'Quantity',
            value: _formatNumber(transfer.quantity),
          ),
        ],
      ),
    );
  }

  String _warehouseLabel(int id) {
    return 'WH-${id.toString().padLeft(2, '0')}';
  }

  String _formatNumber(num value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  String _formatEta(num? hours) {
    if (hours == null || hours <= 0) {
      return 'Now';
    }

    final totalMinutes = (hours * 60).round();
    if (totalMinutes < 60) {
      return '${totalMinutes}m';
    }

    final fullHours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '${fullHours}h';
    }

    return '${fullHours}h ${minutes}m';
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
