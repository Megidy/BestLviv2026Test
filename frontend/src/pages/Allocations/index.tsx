import { useCallback, useEffect, useMemo, useState } from 'react';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { useMap } from '@/features/map/hooks/useMap';
import { useInventory } from '@/features/inventory/hooks/useInventory';
import {
  endpoints,
  request,
  unwrapApiResponse,
  type ApiResponse,
  type Allocation,
  type AllocationStatus,
  type AllocationsResponse,
} from '@/shared/api';
import { Badge } from '@/shared/ui/Badge';
import { Button } from '@/shared/ui/Button';
import { Card, CardContent, CardHeader, CardTitle } from '@/shared/ui/Card';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/shared/ui/Table';
import { formatDateTime } from '@/shared/lib/formatters';

function statusTone(status: AllocationStatus): 'warning' | 'info' | 'success' | 'neutral' | 'danger' {
  switch (status) {
    case 'planned':
      return 'warning';
    case 'approved':
    case 'in_transit':
      return 'info';
    case 'delivered':
      return 'success';
    case 'cancelled':
      return 'neutral';
    default:
      return 'neutral';
  }
}

function statusLabel(status: AllocationStatus): string {
  switch (status) {
    case 'in_transit':
      return 'In transit';
    default:
      return status.charAt(0).toUpperCase() + status.slice(1);
  }
}

export function AllocationsPage() {
  const { user } = useAuth();
  const { points } = useMap({ autoRefreshMs: 0 });

  // Fetch warehouse 1 inventory to resolve resource names (all ~30 resources)
  const { items: resourceItems } = useInventory({ locationId: 1, page: 1, pageSize: 30 });

  const warehouseNameById = useMemo(
    () => Object.fromEntries(
      points.filter((p) => p.type === 'warehouse').map((p) => [p.id, p.name]),
    ),
    [points],
  );

  const resourceNameById = useMemo(
    () => Object.fromEntries(resourceItems.map((r) => [r.resourceId, r.name])),
    [resourceItems],
  );

  const [allocations, setAllocations] = useState<Allocation[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [pendingKeys, setPendingKeys] = useState<Record<string, boolean>>({});

  // dispatcher + admin can manage; admin inherits dispatcher which inherits worker
  const canManage = user?.role === 'dispatcher' || user?.role === 'admin';

  const loadAllocations = useCallback(async () => {
    try {
      const response = await request<ApiResponse<AllocationsResponse>>(
        endpoints.allocations.list,
        { query: { page: 1, pageSize: 50 } },
      );
      const data = unwrapApiResponse(response);
      setAllocations(Array.isArray(data?.allocations) ? data.allocations : []);
      setError(null);
    } catch (caught) {
      setAllocations([]);
      setError(caught instanceof Error ? caught.message : 'Failed to load allocations');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => { void loadAllocations(); }, [loadAllocations]);

  async function handleApprove(id: number) {
    const key = `approve:${id}`;
    setPendingKeys((prev) => ({ ...prev, [key]: true }));
    try {
      await request(endpoints.allocations.approve(id), { method: 'POST' });
      await loadAllocations();
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Failed to approve allocation');
    } finally {
      setPendingKeys((prev) => { const next = { ...prev }; delete next[key]; return next; });
    }
  }

  async function handleReject(id: number) {
    const reason = window.prompt('Reason for rejection (optional):') ?? 'Rejected by dispatcher';
    const key = `reject:${id}`;
    setPendingKeys((prev) => ({ ...prev, [key]: true }));
    try {
      await request(endpoints.allocations.reject(id), {
        method: 'POST',
        body: { reason },
      });
      await loadAllocations();
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Failed to reject allocation');
    } finally {
      setPendingKeys((prev) => { const next = { ...prev }; delete next[key]; return next; });
    }
  }

  async function handleDispatch(id: number) {
    const key = `dispatch:${id}`;
    setPendingKeys((prev) => ({ ...prev, [key]: true }));
    try {
      await request(endpoints.allocations.dispatch(id), { method: 'POST' });
      await loadAllocations();
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Failed to dispatch allocation');
    } finally {
      setPendingKeys((prev) => { const next = { ...prev }; delete next[key]; return next; });
    }
  }

  function warehouseLabel(id: number) {
    const name = warehouseNameById[id];
    return name ? `${name} (#${id})` : `#${id}`;
  }

  function resourceLabel(id: number) {
    const name = resourceNameById[id];
    return name ? `${name} (#${id})` : `#${id}`;
  }

  return (
    <div className="space-y-5 animate-slide-up">
      <div className="flex items-center justify-between gap-3">
        <p className="text-sm text-text-muted">
          {isLoading
            ? 'Loading…'
            : `${allocations.length} allocation${allocations.length === 1 ? '' : 's'} total`}
        </p>
      </div>

      {error ? (
        <div role="alert" className="rounded-xl border border-danger/20 bg-danger/10 px-4 py-3 text-sm text-danger">
          {error}
        </div>
      ) : null}

      <Card>
        <CardHeader>
          <CardTitle>Allocations</CardTitle>
        </CardHeader>
        <CardContent>
          {/* Mobile card list */}
          <div className="space-y-3 lg:hidden" role="list" aria-label="Allocations">
            {isLoading ? (
              <p className="py-10 text-center text-sm text-text-muted">Loading allocations…</p>
            ) : allocations.length === 0 ? (
              <p className="py-10 text-center text-sm text-text-muted">No allocations found.</p>
            ) : (
              allocations.map((alloc) => (
                <div key={alloc.id} role="listitem" className="rounded-xl border border-border bg-surface/50 p-4">
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <p className="text-sm font-semibold text-text">Allocation #{alloc.id}</p>
                      <p className="mt-0.5 text-xs text-text-muted">Request #{alloc.request_id}</p>
                    </div>
                    <Badge tone={statusTone(alloc.status)}>{statusLabel(alloc.status)}</Badge>
                  </div>

                  <div className="mt-3 grid grid-cols-1 gap-2 text-xs">
                    <div>
                      <p className="text-text-muted">Warehouse</p>
                      <p className="mt-0.5 text-text">{warehouseLabel(alloc.source_warehouse_id)}</p>
                    </div>
                    <div>
                      <p className="text-text-muted">Resource</p>
                      <p className="mt-0.5 text-text">{resourceLabel(alloc.resource_id)}</p>
                    </div>
                    <div className="grid grid-cols-2 gap-2">
                      <div>
                        <p className="text-text-muted">Quantity</p>
                        <p className="mt-0.5 text-text">{alloc.quantity}</p>
                      </div>
                      <div>
                        <p className="text-text-muted">Dispatched at</p>
                        <p className="mt-0.5 text-text">
                          {alloc.dispatched_at ? formatDateTime(alloc.dispatched_at) : 'N/A'}
                        </p>
                      </div>
                    </div>
                  </div>

                  {canManage ? (
                    <div className="mt-3 flex flex-wrap gap-2 border-t border-border pt-3">
                      {alloc.status === 'planned' ? (
                        <>
                          <Button
                            size="sm"
                            variant="outline"
                            disabled={Boolean(pendingKeys[`approve:${alloc.id}`])}
                            className="border-success/50 text-success hover:bg-success/10 hover:border-success"
                            onClick={() => void handleApprove(alloc.id)}
                          >
                            {pendingKeys[`approve:${alloc.id}`] ? 'Approving…' : 'Approve'}
                          </Button>
                          <Button
                            size="sm"
                            variant="outline"
                            disabled={Boolean(pendingKeys[`reject:${alloc.id}`])}
                            className="border-danger/50 text-danger hover:bg-danger/10 hover:border-danger"
                            onClick={() => void handleReject(alloc.id)}
                          >
                            {pendingKeys[`reject:${alloc.id}`] ? 'Rejecting…' : 'Reject'}
                          </Button>
                        </>
                      ) : null}
                      {alloc.status === 'approved' ? (
                        <Button
                          size="sm"
                          variant="outline"
                          disabled={Boolean(pendingKeys[`dispatch:${alloc.id}`])}
                          className="border-info/50 text-info hover:bg-info/10 hover:border-info"
                          onClick={() => void handleDispatch(alloc.id)}
                        >
                          {pendingKeys[`dispatch:${alloc.id}`] ? 'Dispatching…' : 'Dispatch'}
                        </Button>
                      ) : null}
                    </div>
                  ) : null}
                </div>
              ))
            )}
          </div>

          {/* Desktop table */}
          <div className="hidden lg:block">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>ID</TableHead>
                  <TableHead>Request</TableHead>
                  <TableHead>Warehouse</TableHead>
                  <TableHead>Resource</TableHead>
                  <TableHead>Qty</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Dispatched at</TableHead>
                  {canManage ? <TableHead className="text-right">Actions</TableHead> : null}
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell className="py-10 text-center text-text-muted" colSpan={canManage ? 8 : 7}>
                      Loading allocations…
                    </TableCell>
                  </TableRow>
                ) : allocations.length === 0 ? (
                  <TableRow>
                    <TableCell className="py-10 text-center text-text-muted" colSpan={canManage ? 8 : 7}>
                      No allocations found.
                    </TableCell>
                  </TableRow>
                ) : (
                  allocations.map((alloc) => (
                    <TableRow key={alloc.id} className="hover:bg-accent/60">
                      <TableCell className="font-medium text-text">#{alloc.id}</TableCell>
                      <TableCell className="text-text-muted">#{alloc.request_id}</TableCell>
                      <TableCell className="text-text-muted">{warehouseLabel(alloc.source_warehouse_id)}</TableCell>
                      <TableCell className="text-text-muted">{resourceLabel(alloc.resource_id)}</TableCell>
                      <TableCell className="text-text-muted">{alloc.quantity}</TableCell>
                      <TableCell>
                        <Badge tone={statusTone(alloc.status)}>{statusLabel(alloc.status)}</Badge>
                      </TableCell>
                      <TableCell className="text-text-muted">
                        {alloc.dispatched_at ? formatDateTime(alloc.dispatched_at) : 'N/A'}
                      </TableCell>
                      {canManage ? (
                        <TableCell className="text-right">
                          <div className="flex items-center justify-end gap-2">
                            {alloc.status === 'planned' ? (
                              <>
                                <Button
                                  size="sm"
                                  variant="outline"
                                  disabled={Boolean(pendingKeys[`approve:${alloc.id}`])}
                                  className="border-success/50 text-success hover:bg-success/10 hover:border-success"
                                  onClick={() => void handleApprove(alloc.id)}
                                >
                                  {pendingKeys[`approve:${alloc.id}`] ? 'Approving…' : 'Approve'}
                                </Button>
                                <Button
                                  size="sm"
                                  variant="outline"
                                  disabled={Boolean(pendingKeys[`reject:${alloc.id}`])}
                                  className="border-danger/50 text-danger hover:bg-danger/10 hover:border-danger"
                                  onClick={() => void handleReject(alloc.id)}
                                >
                                  {pendingKeys[`reject:${alloc.id}`] ? 'Rejecting…' : 'Reject'}
                                </Button>
                              </>
                            ) : null}
                            {alloc.status === 'approved' ? (
                              <Button
                                size="sm"
                                variant="outline"
                                disabled={Boolean(pendingKeys[`dispatch:${alloc.id}`])}
                                className="border-info/50 text-info hover:bg-info/10 hover:border-info"
                                onClick={() => void handleDispatch(alloc.id)}
                              >
                                {pendingKeys[`dispatch:${alloc.id}`] ? 'Dispatching…' : 'Dispatch'}
                              </Button>
                            ) : null}
                          </div>
                        </TableCell>
                      ) : null}
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
