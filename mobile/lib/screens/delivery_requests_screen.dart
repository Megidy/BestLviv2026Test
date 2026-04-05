import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DeliveryRequestsScreen extends StatefulWidget {
  const DeliveryRequestsScreen({
    super.key,
    required this.actorRole,
    required this.requests,
    required this.allocations,
    required this.totalRequests,
    required this.totalAllocations,
    required this.selectedRequestStatus,
    required this.selectedAllocationStatus,
    required this.isBusy,
    this.errorMessage,
    required this.onBack,
    required this.onRefresh,
    required this.onRequestStatusFilterChange,
    required this.onAllocationStatusFilterChange,
    required this.onRunAllocate,
    required this.onOpenRequest,
  });

  final UserRole actorRole;
  final List<DeliveryRequestSummary> requests;
  final List<AllocationRecord> allocations;
  final int totalRequests;
  final int totalAllocations;
  final String? selectedRequestStatus;
  final String? selectedAllocationStatus;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final ValueChanged<String?> onRequestStatusFilterChange;
  final ValueChanged<String?> onAllocationStatusFilterChange;
  final VoidCallback onRunAllocate;
  final ValueChanged<DeliveryRequestSummary> onOpenRequest;

  @override
  State<DeliveryRequestsScreen> createState() => _DeliveryRequestsScreenState();
}

enum _DeliverySection {
  requests,
  allocations,
}

class _DeliveryRequestsScreenState extends State<DeliveryRequestsScreen> {
  _DeliverySection _activeSection = _DeliverySection.requests;

  static const List<_StatusOption> _requestStatusOptions = [
    _StatusOption(value: null, label: 'All'),
    _StatusOption(value: 'pending', label: 'Pending'),
    _StatusOption(value: 'allocated', label: 'Allocated'),
    _StatusOption(value: 'in_transit', label: 'In transit'),
    _StatusOption(value: 'delivered', label: 'Delivered'),
    _StatusOption(value: 'cancelled', label: 'Cancelled'),
  ];

  static const List<_StatusOption> _allocationStatusOptions = [
    _StatusOption(value: null, label: 'All'),
    _StatusOption(value: 'planned', label: 'Planned'),
    _StatusOption(value: 'approved', label: 'Approved'),
    _StatusOption(value: 'in_transit', label: 'In transit'),
    _StatusOption(value: 'delivered', label: 'Delivered'),
    _StatusOption(value: 'cancelled', label: 'Cancelled'),
  ];

  bool get _showRequests => _activeSection == _DeliverySection.requests;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingCount = widget.requests
        .where((request) => request.status == DeliveryRequestStatus.pending)
        .length;

    final listItems = _showRequests ? widget.requests.length : widget.allocations.length;
    final selectedStatus =
        _showRequests ? widget.selectedRequestStatus : widget.selectedAllocationStatus;
    final filterOptions =
        _showRequests ? _requestStatusOptions : _allocationStatusOptions;

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
                  'DELIVERY REQUESTS',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.2),
                ),
              ),
              IconButton(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DetailStatCard(
                  label: 'Total',
                  value: widget.totalRequests.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DetailStatCard(
                  label: 'Pending',
                  value: pendingCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DetailStatCard(
                  label: 'Alloc',
                  value: widget.totalAllocations.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.actorRole == UserRole.dispatcher)
            OutlineActionButton(
              label: 'Run Allocate',
              icon: Icons.hub_rounded,
              onTap: widget.onRunAllocate,
              fillWidth: true,
            ),
          const SizedBox(height: 12),
          _SectionSwitcher(
            activeSection: _activeSection,
            onChanged: (section) {
              setState(() {
                _activeSection = section;
              });
            },
          ),
          const SizedBox(height: 10),
          _StatusFilterRow(
            selectedValue: selectedStatus,
            options: filterOptions,
            onChanged: (next) {
              if (_showRequests) {
                widget.onRequestStatusFilterChange(next);
              } else {
                widget.onAllocationStatusFilterChange(next);
              }
            },
          ),
          if (widget.errorMessage != null && widget.errorMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.redAlert,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                if (listItems == 0)
                  PanelCard(
                    child: Text(
                      _showRequests
                          ? 'No delivery requests for selected filter.'
                          : 'No allocations for selected filter.',
                    ),
                  )
                else
                  ListView.separated(
                    itemCount: listItems,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (_showRequests) {
                        final request = widget.requests[index];
                        return _DeliveryRequestTile(
                          request: request,
                          onTap: () => widget.onOpenRequest(request),
                        );
                      }

                      return _AllocationTile(
                        allocation: widget.allocations[index],
                      );
                    },
                  ),
                if (widget.isBusy)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: AppColors.warmGold,
                      backgroundColor: AppColors.stroke,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOption {
  const _StatusOption({
    required this.value,
    required this.label,
  });

  final String? value;
  final String label;
}

class _SectionSwitcher extends StatelessWidget {
  const _SectionSwitcher({
    required this.activeSection,
    required this.onChanged,
  });

  final _DeliverySection activeSection;
  final ValueChanged<_DeliverySection> onChanged;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Requests',
              isSelected: activeSection == _DeliverySection.requests,
              onTap: () => onChanged(_DeliverySection.requests),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SegmentButton(
              label: 'Allocations',
              isSelected: activeSection == _DeliverySection.allocations,
              onTap: () => onChanged(_DeliverySection.allocations),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mutedGold : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.warmGold : AppColors.stroke,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected ? AppColors.creamText : AppColors.softText,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  });

  final String? selectedValue;
  final List<_StatusOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          return _StatusFilterChip(
            label: option.label,
            selected: selectedValue == option.value,
            onTap: () => onChanged(option.value),
          );
        },
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.mutedGold : AppColors.panel,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.warmGold : AppColors.stroke,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.creamText : AppColors.softText,
              ),
        ),
      ),
    );
  }
}

class _AllocationTile extends StatelessWidget {
  const _AllocationTile({required this.allocation});

  final AllocationRecord allocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Ink(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('ALLOC #${allocation.id}', style: theme.textTheme.titleMedium),
              const Spacer(),
              StatusPill(
                label: allocation.statusLabel.toUpperCase(),
                color: _allocationStatusColor(allocation.status),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: 'Request #${allocation.requestId}'),
              _InfoChip(label: 'Qty ${_formatQuantity(allocation.quantity)}'),
              _InfoChip(label: 'WH ${allocation.sourceWarehouseId}'),
              _InfoChip(label: 'Resource ${allocation.resourceId}'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Updated ${_formatDateTime(allocation.updatedAt ?? allocation.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.softText),
          ),
        ],
      ),
    );
  }
}

class _DeliveryRequestTile extends StatelessWidget {
  const _DeliveryRequestTile({
    required this.request,
    required this.onTap,
  });

  final DeliveryRequestSummary request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('REQ #${request.id}', style: theme.textTheme.titleMedium),
                const Spacer(),
                StatusPill(
                  label: request.statusLabel.toUpperCase(),
                  color: _requestStatusColor(request.status),
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(label: 'Priority ${request.priorityLabel}'),
                _InfoChip(label: 'Qty ${_formatQuantity(request.quantity)}'),
                _InfoChip(label: 'Resource ${request.resourceId}'),
                _InfoChip(label: 'Destination ${request.destinationId}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Updated ${_formatDateTime(request.updatedAt ?? request.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.softText,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.softText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.canvas.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.creamText,
            ),
      ),
    );
  }
}

Color _requestStatusColor(DeliveryRequestStatus status) {
  return switch (status) {
    DeliveryRequestStatus.pending => AppColors.amberWarn,
    DeliveryRequestStatus.allocated => AppColors.warmGold,
    DeliveryRequestStatus.inTransit => AppColors.warmGold,
    DeliveryRequestStatus.delivered => AppColors.greenOk,
    DeliveryRequestStatus.cancelled => AppColors.redAlert,
    DeliveryRequestStatus.unknown => AppColors.softText,
  };
}

Color _allocationStatusColor(AllocationStatus status) {
  return switch (status) {
    AllocationStatus.planned => AppColors.amberWarn,
    AllocationStatus.approved => AppColors.warmGold,
    AllocationStatus.inTransit => AppColors.warmGold,
    AllocationStatus.delivered => AppColors.greenOk,
    AllocationStatus.cancelled => AppColors.redAlert,
    AllocationStatus.unknown => AppColors.softText,
  };
}

String _formatQuantity(num value) {
  if (value % 1 == 0) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'n/a';
  }
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month $hour:$minute';
}
