import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DeliveryRequestsScreen extends StatelessWidget {
  const DeliveryRequestsScreen({
    super.key,
    required this.requests,
    required this.allocations,
    required this.totalRequests,
    required this.totalAllocations,
    required this.selectedRequestStatus,
    required this.selectedRequestPriority,
    required this.selectedAllocationStatus,
    required this.requestsPage,
    required this.allocationsPage,
    required this.requestsPageSize,
    required this.allocationsPageSize,
    required this.isBusy,
    this.errorMessage,
    required this.onBack,
    required this.onRefresh,
    required this.onRequestStatusFilterChange,
    required this.onRequestPriorityFilterChange,
    required this.onAllocationStatusFilterChange,
    required this.onRequestsPageChange,
    required this.onAllocationsPageChange,
    required this.onRunAllocate,
    required this.onOpenRequest,
  });

  final List<DeliveryRequestSummary> requests;
  final List<AllocationRecord> allocations;
  final int totalRequests;
  final int totalAllocations;
  final String? selectedRequestStatus;
  final String? selectedRequestPriority;
  final String? selectedAllocationStatus;
  final int requestsPage;
  final int allocationsPage;
  final int requestsPageSize;
  final int allocationsPageSize;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final ValueChanged<String?> onRequestStatusFilterChange;
  final ValueChanged<String?> onRequestPriorityFilterChange;
  final ValueChanged<String?> onAllocationStatusFilterChange;
  final ValueChanged<int> onRequestsPageChange;
  final ValueChanged<int> onAllocationsPageChange;
  final VoidCallback onRunAllocate;
  final ValueChanged<DeliveryRequestSummary> onOpenRequest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingCount = requests
        .where((request) => request.status == DeliveryRequestStatus.pending)
        .length;
    final hasNextRequestsPage = requestsPage * requestsPageSize < totalRequests;
    final hasNextAllocationsPage =
      allocationsPage * allocationsPageSize < totalAllocations;
    final requestRangeStart =
      totalRequests == 0 ? 0 : ((requestsPage - 1) * requestsPageSize) + 1;
    final requestRangeEnd = math.min(requestsPage * requestsPageSize, totalRequests);
    final allocationRangeStart = totalAllocations == 0
      ? 0
      : ((allocationsPage - 1) * allocationsPageSize) + 1;
    final allocationRangeEnd =
      math.min(allocationsPage * allocationsPageSize, totalAllocations);

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
                  'DELIVERY REQUESTS',
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
          Row(
            children: [
              Expanded(
                child: DetailStatCard(
                  label: 'TOTAL',
                  value: totalRequests.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DetailStatCard(
                  label: 'PENDING',
                  value: pendingCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DetailStatCard(
                  label: 'ALLOCATIONS',
                  value: totalAllocations.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlineActionButton(
                  label: 'Refresh',
                  icon: Icons.refresh_rounded,
                  onTap: onRefresh,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlineActionButton(
                  label: 'Run Allocate',
                  icon: Icons.hub_rounded,
                  onTap: onRunAllocate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PanelCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FILTERS',
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1,
                    color: AppColors.softText,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 190,
                      child: _FilterDropdown(
                        label: 'Request Status',
                        value: selectedRequestStatus,
                        items: const {
                          'pending': 'Pending',
                          'allocated': 'Allocated',
                          'in_transit': 'In Transit',
                          'delivered': 'Delivered',
                          'cancelled': 'Cancelled',
                        },
                        onChanged: onRequestStatusFilterChange,
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: _FilterDropdown(
                        label: 'Request Priority',
                        value: selectedRequestPriority,
                        items: const {
                          'urgent': 'Urgent',
                          'critical': 'Critical',
                          'elevated': 'Elevated',
                          'normal': 'Normal',
                        },
                        onChanged: onRequestPriorityFilterChange,
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: _FilterDropdown(
                        label: 'Allocation Status',
                        value: selectedAllocationStatus,
                        items: const {
                          'planned': 'Planned',
                          'approved': 'Approved',
                          'in_transit': 'In Transit',
                          'delivered': 'Delivered',
                          'cancelled': 'Cancelled',
                        },
                        onChanged: onAllocationStatusFilterChange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                if (requests.isEmpty && allocations.isEmpty)
                  const PanelCard(
                    child: Text('No delivery requests or allocations returned from API.'),
                  )
                else
                  ListView(
                    children: [
                      Text(
                        'REQUESTS $requestRangeStart-$requestRangeEnd / $totalRequests',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.softText,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (requests.isEmpty)
                        const PanelCard(
                          child: Text('No delivery requests for selected filters.'),
                        )
                      else
                        ...requests.map(
                          (request) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _DeliveryRequestTile(
                              request: request,
                              onTap: () => onOpenRequest(request),
                            ),
                          ),
                        ),
                      _PaginationRow(
                        page: requestsPage,
                        hasNextPage: hasNextRequestsPage,
                        onPageChange: onRequestsPageChange,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'ALLOCATIONS $allocationRangeStart-$allocationRangeEnd / $totalAllocations',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.softText,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (allocations.isEmpty)
                        const PanelCard(
                          child: Text('No allocations for selected filters.'),
                        )
                      else
                        ...allocations.map(
                          (allocation) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AllocationTile(allocation: allocation),
                          ),
                        ),
                      _PaginationRow(
                        page: allocationsPage,
                        hasNextPage: hasNextAllocationsPage,
                        onPageChange: onAllocationsPageChange,
                      ),
                    ],
                  ),
                if (isBusy)
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

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  static const String _allValue = '__all__';

  @override
  Widget build(BuildContext context) {
    final selectedValue = value ?? _allValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.softText),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.stroke),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                  value: _allValue,
                  child: Text('All'),
                ),
                ...items.entries.map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                ),
              ],
              onChanged: (next) {
                if (next == null) {
                  return;
                }
                onChanged(next == _allValue ? null : next);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PaginationRow extends StatelessWidget {
  const _PaginationRow({
    required this.page,
    required this.hasNextPage,
    required this.onPageChange,
  });

  final int page;
  final bool hasNextPage;
  final ValueChanged<int> onPageChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: page > 1 ? () => onPageChange(page - 1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text('Page $page'),
        IconButton(
          onPressed: hasNextPage ? () => onPageChange(page + 1) : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
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
                color: _statusColor(allocation.status),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Request #${allocation.requestId} • Qty ${allocation.quantity}',
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.creamText),
          ),
          const SizedBox(height: 4),
          Text(
            'Warehouse ${allocation.sourceWarehouseId} • Resource ${allocation.resourceId}',
            style: theme.textTheme.bodyMedium,
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
    final statusColor = _statusColor(request.status);

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
                Text(
                  'REQ #${request.id}',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                StatusPill(
                  label: request.statusLabel.toUpperCase(),
                  color: statusColor,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Resource ${request.resourceId} • Qty ${request.quantity}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.creamText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Priority ${request.priorityLabel} • Destination ${request.destinationId}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
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
