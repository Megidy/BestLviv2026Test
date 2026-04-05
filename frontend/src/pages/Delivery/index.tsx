import { useEffect, useMemo, useState } from 'react';
import { Plus } from 'lucide-react';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { useMap } from '@/features/map/hooks/useMap';
import {
  endpoints,
  request,
  unwrapApiResponse,
  type ApiResponse,
  type DeliveryRequest,
  type DeliveryPriority,
  type DeliveryStatus,
  type DeliveryRequestsResponse,
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
import { formatDateTime, formatRelativeCountdown } from '@/shared/lib/formatters';

function priorityTone(priority: DeliveryPriority): 'danger' | 'warning' | 'info' | 'neutral' {
  switch (priority) {
    case 'urgent':
    case 'critical':
      return 'danger';
    case 'elevated':
      return 'warning';
    default:
      return 'info';
  }
}

function statusTone(status: DeliveryStatus): 'warning' | 'info' | 'success' | 'neutral' {
  switch (status) {
    case 'pending':
      return 'warning';
    case 'allocated':
    case 'in_transit':
      return 'info';
    case 'delivered':
      return 'success';
    default:
      return 'neutral';
  }
}

function statusLabel(status: DeliveryStatus): string {
  switch (status) {
    case 'in_transit':
      return 'In transit';
    default:
      return status.charAt(0).toUpperCase() + status.slice(1);
  }
}

export function DeliveryPage() {
  const { user } = useAuth();
  const { points } = useMap({ autoRefreshMs: 0 });
  const [requests, setRequests] = useState<DeliveryRequest[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const customerNameById = useMemo(
    () => Object.fromEntries(
      points.filter((p) => p.type === 'customer').map((p) => [p.id, p.name]),
    ),
    [points],
  );

  useEffect(() => {
    let active = true;

    async function loadRequests() {
      try {
        const response = await request<ApiResponse<DeliveryRequestsResponse>>(
          endpoints.requests.list,
          { query: { page: 1, pageSize: 50 } },
        );

        if (active) {
          const data = unwrapApiResponse(response);
          setRequests(Array.isArray(data?.requests) ? data.requests : []);
          setError(null);
        }
      } catch (caught) {
        if (active) {
          setRequests([]);
          setError(caught instanceof Error ? caught.message : 'Failed to load delivery requests');
        }
      } finally {
        if (active) setIsLoading(false);
      }
    }

    void loadRequests();
    return () => { active = false; };
  }, []);

  // dispatcher inherits worker functions; admin inherits all
  const canCreate = Boolean(user);

  function destinationLabel(id: number) {
    const name = customerNameById[id];
    return name ? `${name} (#${id})` : `#${id}`;
  }

  return (
    <div className="space-y-5 animate-slide-up">
      <div className="flex items-center justify-between gap-3">
        <p className="text-sm text-text-muted">
          {isLoading ? 'Loading…' : `${requests.length} request${requests.length === 1 ? '' : 's'} total`}
        </p>
        {canCreate ? (
          <Button size="sm" aria-label="Create new delivery request">
            <Plus size={15} className="mr-1.5" aria-hidden="true" />
            New request
          </Button>
        ) : null}
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Delivery requests</CardTitle>
        </CardHeader>
        <CardContent>
          {/* Mobile card list */}
          <div className="space-y-3 lg:hidden" role="list" aria-label="Delivery requests">
            {isLoading ? (
              <p className="py-10 text-center text-sm text-text-muted">Loading delivery requests…</p>
            ) : error ? (
              <p className="py-10 text-center text-sm text-danger" role="alert">{error}</p>
            ) : requests.length === 0 ? (
              <p className="py-10 text-center text-sm text-text-muted">No delivery requests found.</p>
            ) : (
              requests.map((req) => (
                <div key={req.id} role="listitem" className="rounded-xl border border-border bg-surface/50 p-4">
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <p className="text-sm font-semibold text-text">Request #{req.id}</p>
                      <p className="mt-0.5 truncate text-xs text-text-muted">
                        {destinationLabel(req.destination_id)}
                      </p>
                    </div>
                    <div className="flex shrink-0 flex-col items-end gap-1.5">
                      <Badge tone={priorityTone(req.priority)}>{req.priority}</Badge>
                      <Badge tone={statusTone(req.status)}>{statusLabel(req.status)}</Badge>
                    </div>
                  </div>

                  <div className="mt-3 grid grid-cols-2 gap-2 text-xs">
                    <div>
                      <p className="text-text-muted">Items</p>
                      <p className="mt-0.5 text-text">{req.items ? req.items.length : 1}</p>
                    </div>
                    <div>
                      <p className="text-text-muted">Quantity</p>
                      <p className="mt-0.5 text-text">{req.quantity}</p>
                    </div>
                    <div>
                      <p className="text-text-muted">ETA</p>
                      <p className="mt-0.5 text-text">
                        {req.arrive_till ? formatRelativeCountdown(req.arrive_till) : 'N/A'}
                      </p>
                    </div>
                    <div>
                      <p className="text-text-muted">Created</p>
                      <p className="mt-0.5 text-text">{formatDateTime(req.created_at)}</p>
                    </div>
                  </div>
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
                  <TableHead>Destination</TableHead>
                  <TableHead>Priority</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Items</TableHead>
                  <TableHead>ETA</TableHead>
                  <TableHead className="text-right">Created</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell className="py-10 text-center text-text-muted" colSpan={7}>
                      Loading delivery requests…
                    </TableCell>
                  </TableRow>
                ) : error ? (
                  <TableRow>
                    <TableCell className="py-10 text-center text-danger" colSpan={7}>{error}</TableCell>
                  </TableRow>
                ) : requests.length === 0 ? (
                  <TableRow>
                    <TableCell className="py-10 text-center text-text-muted" colSpan={7}>
                      No delivery requests found.
                    </TableCell>
                  </TableRow>
                ) : (
                  requests.map((req) => (
                    <TableRow key={req.id} className="hover:bg-accent/60">
                      <TableCell className="font-medium text-text">#{req.id}</TableCell>
                      <TableCell className="text-text-muted">{destinationLabel(req.destination_id)}</TableCell>
                      <TableCell>
                        <Badge tone={priorityTone(req.priority)}>{req.priority}</Badge>
                      </TableCell>
                      <TableCell>
                        <Badge tone={statusTone(req.status)}>{statusLabel(req.status)}</Badge>
                      </TableCell>
                      <TableCell className="text-text-muted">{req.items ? req.items.length : 1}</TableCell>
                      <TableCell className="text-text-muted">
                        {req.arrive_till ? formatRelativeCountdown(req.arrive_till) : 'N/A'}
                      </TableCell>
                      <TableCell className="text-right text-text-muted">
                        {formatDateTime(req.created_at)}
                      </TableCell>
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
