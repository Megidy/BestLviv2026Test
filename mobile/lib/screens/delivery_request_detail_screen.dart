import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DeliveryRequestDetailScreen extends StatelessWidget {
  const DeliveryRequestDetailScreen({
    super.key,
    required this.detail,
    required this.actorRole,
    required this.isBusy,
    this.errorMessage,
    required this.onBack,
    required this.onRefresh,
    required this.onEscalate,
    required this.onApproveAll,
    required this.onCancel,
    required this.onDeliver,
    required this.onUpdateItemQuantity,
    required this.onApproveAllocation,
    required this.onDispatchAllocation,
    required this.onRejectAllocation,
  });

  final DeliveryRequestDetail detail;
  final UserRole actorRole;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onEscalate;
  final VoidCallback onApproveAll;
  final VoidCallback onCancel;
  final VoidCallback onDeliver;
  final void Function(int resourceId, num quantity) onUpdateItemQuantity;
  final ValueChanged<int> onApproveAllocation;
  final ValueChanged<int> onDispatchAllocation;
  final void Function(int allocationId, String reason) onRejectAllocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = detail.request;
    final canEscalate = _canEscalate(actorRole, request.status);
    final canApproveAll = _canApproveAll(
      actorRole,
      request.status,
      detail.allocations,
    );
    final canCancel = _canCancel(actorRole, request.status);
    final canDeliver = _canDeliver(actorRole, request.status);
    final canUpdateItems = _canUpdateItems(actorRole, request.status);
    final timeline = _buildTimeline(detail);

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
                  'REQUEST #${request.id}',
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
          _RequestCard(request: request),
          const SizedBox(height: 12),
          Text(
            'TIMELINE',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          const SizedBox(height: 8),
          if (timeline.isEmpty)
            const PanelCard(
              child: Text('No request timeline events available.'),
            )
          else
            _TimelineCard(events: timeline),
          const SizedBox(height: 12),
          Text(
            'REQUEST ACTIONS',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Actions are enabled by role and current status.',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.softText),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (canEscalate)
                SizedBox(
                  width: 158,
                  child: OutlineActionButton(
                    label: 'Escalate',
                    icon: Icons.trending_up_rounded,
                    onTap: onEscalate,
                  ),
                ),
              if (canApproveAll)
                SizedBox(
                  width: 158,
                  child: OutlineActionButton(
                    label: 'Approve All',
                    icon: Icons.verified_rounded,
                    onTap: onApproveAll,
                  ),
                ),
              if (canCancel)
                SizedBox(
                  width: 158,
                  child: OutlineActionButton(
                    label: 'Cancel',
                    icon: Icons.block_rounded,
                    accent: AppColors.redAlert,
                    onTap: onCancel,
                  ),
                ),
              if (canDeliver)
                SizedBox(
                  width: 158,
                  child: OutlineActionButton(
                    label: 'Deliver',
                    icon: Icons.local_shipping_rounded,
                    onTap: onDeliver,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'REQUEST ITEMS',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          const SizedBox(height: 8),
          if (detail.items.isEmpty)
            const PanelCard(
              child: Text('No items attached to this request.'),
            ),
          for (final item in detail.items) ...[
            _ItemCard(
              item: item,
              onIncrease: canUpdateItems
                  ? () => onUpdateItemQuantity(
                        item.resourceId,
                        item.quantity + 1,
                      )
                  : null,
              onDecrease: !canUpdateItems || item.quantity <= 1
                  ? null
                  : () => onUpdateItemQuantity(
                        item.resourceId,
                        item.quantity - 1,
                      ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          Text(
            'ALLOCATIONS',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.softText,
            ),
          ),
          const SizedBox(height: 8),
          if (detail.allocations.isEmpty)
            const PanelCard(
              child: Text('No allocations yet for this request.'),
            ),
          for (final allocation in detail.allocations) ...[
            _AllocationCard(
              allocation: allocation,
              actorRole: actorRole,
              onApprove: () => onApproveAllocation(allocation.id),
              onDispatch: () => onDispatchAllocation(allocation.id),
              onReject: () => onRejectAllocation(
                allocation.id,
                'Rejected in mobile dispatcher workflow.',
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.redAlert,
              ),
            ),
          ],
          if (isBusy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              minHeight: 3,
              color: AppColors.warmGold,
              backgroundColor: AppColors.stroke,
            ),
          ],
        ],
      ),
    );
  }

  bool _canEscalate(UserRole role, DeliveryRequestStatus status) {
    if (role != UserRole.worker && role != UserRole.dispatcher) {
      return false;
    }
    return status == DeliveryRequestStatus.pending ||
        status == DeliveryRequestStatus.allocated;
  }

  bool _canApproveAll(
    UserRole role,
    DeliveryRequestStatus status,
    List<AllocationRecord> allocations,
  ) {
    if (role != UserRole.dispatcher || status != DeliveryRequestStatus.allocated) {
      return false;
    }
    return allocations.any((allocation) => allocation.status == AllocationStatus.planned);
  }

  bool _canCancel(UserRole role, DeliveryRequestStatus status) {
    if (role != UserRole.dispatcher) {
      return false;
    }
    return status == DeliveryRequestStatus.pending ||
        status == DeliveryRequestStatus.allocated;
  }

  bool _canDeliver(UserRole role, DeliveryRequestStatus status) {
    return role == UserRole.worker && status == DeliveryRequestStatus.inTransit;
  }

  bool _canUpdateItems(UserRole role, DeliveryRequestStatus status) {
    if (role != UserRole.worker && role != UserRole.dispatcher) {
      return false;
    }
    return status == DeliveryRequestStatus.pending;
  }

  List<_TimelineEvent> _buildTimeline(DeliveryRequestDetail requestDetail) {
    final request = requestDetail.request;
    final events = <_TimelineEvent>[];

    if (request.createdAt != null) {
      events.add(
        _TimelineEvent(
          time: request.createdAt!,
          title: 'Request created',
          subtitle: 'Priority ${request.priorityLabel}',
        ),
      );
    }

    if (request.updatedAt != null) {
      events.add(
        _TimelineEvent(
          time: request.updatedAt!,
          title: 'Request updated',
          subtitle: 'Status ${request.statusLabel}',
        ),
      );
    }

    if (request.arriveTill != null) {
      events.add(
        _TimelineEvent(
          time: request.arriveTill!,
          title: 'Expected arrival deadline',
          subtitle: 'Destination ${request.destinationId}',
        ),
      );
    }

    for (final allocation in requestDetail.allocations) {
      if (allocation.createdAt != null) {
        events.add(
          _TimelineEvent(
            time: allocation.createdAt!,
            title: 'Allocation #${allocation.id} created',
            subtitle: 'Warehouse ${allocation.sourceWarehouseId}',
          ),
        );
      }

      if (allocation.updatedAt != null) {
        events.add(
          _TimelineEvent(
            time: allocation.updatedAt!,
            title: 'Allocation #${allocation.id} updated',
            subtitle: 'Status ${allocation.statusLabel}',
          ),
        );
      }
    }

    events.sort((a, b) => b.time.compareTo(a.time));
    return events;
  }
}

class _TimelineEvent {
  const _TimelineEvent({
    required this.time,
    required this.title,
    required this.subtitle,
  });

  final DateTime time;
  final String title;
  final String subtitle;
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.events});

  final List<_TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PanelCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (int index = 0; index < events.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.warmGold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (index != events.length - 1)
                      Container(
                        width: 2,
                        height: 34,
                        color: AppColors.stroke,
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(events[index].title, style: theme.textTheme.titleSmall),
                      Text(
                        events[index].subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.softText,
                        ),
                      ),
                      Text(
                        _formatTime(events[index].time),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.softText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (index != events.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final DeliveryRequestSummary request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PanelCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Destination ${request.destinationId}',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              StatusPill(
                label: request.statusLabel.toUpperCase(),
                color: _statusColor(request.status),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          DetailLine(label: 'Resource ID', value: request.resourceId.toString()),
          DetailLine(label: 'Quantity', value: request.quantity.toString()),
          DetailLine(label: 'Priority', value: request.priorityLabel),
          DetailLine(label: 'Owner User ID', value: request.userId.toString()),
        ],
      ),
    );
  }

  Color _statusColor(DeliveryRequestStatus status) {
    return switch (status) {
      DeliveryRequestStatus.pending => AppColors.amberWarn,
      DeliveryRequestStatus.allocated => AppColors.warmGold,
      DeliveryRequestStatus.inTransit => AppColors.warmGold,
      DeliveryRequestStatus.delivered => AppColors.greenOk,
      DeliveryRequestStatus.cancelled => AppColors.redAlert,
      DeliveryRequestStatus.unknown => AppColors.softText,
    };
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
  });

  final DeliveryRequestItem item;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PanelCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Item #${item.id}', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          DetailLine(label: 'Resource ID', value: item.resourceId.toString()),
          DetailLine(label: 'Quantity', value: item.quantity.toString()),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlineActionButton(
                  label: '-1 qty',
                  icon: Icons.remove_rounded,
                  onTap: onDecrease ?? () {},
                  accent:
                      onDecrease == null ? AppColors.softText : AppColors.warmGold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlineActionButton(
                  label: '+1 qty',
                  icon: Icons.add_rounded,
                  onTap: onIncrease ?? () {},
                  accent:
                      onIncrease == null ? AppColors.softText : AppColors.warmGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({
    required this.allocation,
    required this.actorRole,
    required this.onApprove,
    required this.onDispatch,
    required this.onReject,
  });

  final AllocationRecord allocation;
  final UserRole actorRole;
  final VoidCallback onApprove;
  final VoidCallback onDispatch;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canApprove = actorRole == UserRole.dispatcher &&
        allocation.status == AllocationStatus.planned;
    final canReject = actorRole == UserRole.dispatcher &&
        allocation.status == AllocationStatus.planned;
    final canDispatch = actorRole == UserRole.worker &&
        allocation.status == AllocationStatus.approved;

    return PanelCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Allocation #${allocation.id}', style: theme.textTheme.titleMedium),
              const Spacer(),
              StatusPill(
                label: allocation.statusLabel.toUpperCase(),
                color: _statusColor(allocation.status),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          DetailLine(label: 'Source Warehouse', value: allocation.sourceWarehouseId.toString()),
          DetailLine(label: 'Resource ID', value: allocation.resourceId.toString()),
          DetailLine(label: 'Quantity', value: allocation.quantity.toString()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (canApprove)
                SizedBox(
                  width: 134,
                  child: OutlineActionButton(
                    label: 'Approve',
                    icon: Icons.verified_rounded,
                    onTap: onApprove,
                  ),
                ),
              if (canDispatch)
                SizedBox(
                  width: 134,
                  child: OutlineActionButton(
                    label: 'Dispatch',
                    icon: Icons.local_shipping_rounded,
                    onTap: onDispatch,
                  ),
                ),
              if (canReject)
                SizedBox(
                  width: 134,
                  child: OutlineActionButton(
                    label: 'Reject',
                    icon: Icons.cancel_rounded,
                    accent: AppColors.redAlert,
                    onTap: onReject,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(AllocationStatus status) {
    return switch (status) {
      AllocationStatus.planned => AppColors.amberWarn,
      AllocationStatus.approved => AppColors.warmGold,
      AllocationStatus.inTransit => AppColors.warmGold,
      AllocationStatus.delivered => AppColors.greenOk,
      AllocationStatus.cancelled => AppColors.redAlert,
      AllocationStatus.unknown => AppColors.softText,
    };
  }
}
