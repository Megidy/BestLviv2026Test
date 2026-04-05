import { useEffect, useMemo, useState } from 'react';
import { ChevronUp, ChevronDown, ChevronsUpDown, Plus, X } from 'lucide-react';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { useMap } from '@/features/map/hooks/useMap';
import { useInventory } from '@/features/inventory/hooks/useInventory';
import {
  endpoints,
  invalidateCache,
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
import { Input } from '@/shared/ui/Input';
import { Skeleton, SkeletonRow } from '@/shared/ui/Skeleton';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/shared/ui/Table';
import { formatDateTime, formatRelativeCountdown } from '@/shared/lib/formatters';

type SortKey = 'quantity';
type SortDir = 'asc' | 'desc';

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
    case 'pending': return 'warning';
    case 'allocated':
    case 'in_transit': return 'info';
    case 'delivered': return 'success';
    default: return 'neutral';
  }
}

function statusLabel(status: DeliveryStatus): string {
  return status === 'in_transit' ? 'In transit' : status.charAt(0).toUpperCase() + status.slice(1);
}

function SortIcon({ active, dir }: { active: boolean; dir: SortDir }) {
  if (!active) return <ChevronsUpDown size={13} className="ml-1 inline opacity-40" />;
  return dir === 'asc'
    ? <ChevronUp size={13} className="ml-1 inline text-primary" />
    : <ChevronDown size={13} className="ml-1 inline text-primary" />;
}

const PRIORITIES: DeliveryPriority[] = ['normal', 'elevated', 'critical', 'urgent'];

export function DeliveryPage() {
  const { user } = useAuth();
  const { points } = useMap({ autoRefreshMs: 0 });
  const { items: resourceItems } = useInventory({ locationId: 1, page: 1, pageSize: 30 });

  const [requests, setRequests] = useState<DeliveryRequest[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [sortKey, setSortKey] = useState<SortKey | null>(null);
  const [sortDir, setSortDir] = useState<SortDir>('desc');

  // New request modal state
  const [showModal, setShowModal] = useState(false);
  const [formDestination, setFormDestination] = useState('');
  const [formResource, setFormResource] = useState('');
  const [formQty, setFormQty] = useState('');
  const [formPriority, setFormPriority] = useState<DeliveryPriority>('normal');
  const [formArriveTill, setFormArriveTill] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const customerPoints = useMemo(() => points.filter((p) => p.type === 'customer'), [points]);

  const customerNameById = useMemo(
    () => Object.fromEntries(customerPoints.map((p) => [p.id, p.name])),
    [customerPoints],
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
          const sorted = (Array.isArray(data?.requests) ? data.requests : [])
            .sort((a, b) => b.id - a.id);
          setRequests(sorted);
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

  const displayedRequests = useMemo(() => {
    if (!sortKey) return requests;
    return [...requests].sort((a, b) => {
      const diff = a[sortKey] - b[sortKey];
      return sortDir === 'asc' ? diff : -diff;
    });
  }, [requests, sortKey, sortDir]);

  function toggleSort(key: SortKey) {
    if (sortKey === key) {
      setSortDir((d) => (d === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortKey(key);
      setSortDir('desc');
    }
  }

  function destinationLabel(id: number) {
    const name = customerNameById[id];
    return name ? `${name} (#${id})` : `#${id}`;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!formDestination || !formResource || !formQty) {
      setFormError('Destination, resource and quantity are required.');
      return;
    }
    setIsSubmitting(true);
    setFormError(null);
    try {
      await request(endpoints.requests.create, {
        method: 'POST',
        body: {
          destination_id: Number(formDestination),
          items: [{ resource_id: Number(formResource), quantity: Number(formQty) }],
          priority: formPriority,
          arrive_till: formArriveTill ? new Date(formArriveTill).toISOString() : undefined,
        },
      });
      // Bust cache then reload
      invalidateCache(endpoints.requests.list);
      const response = await request<ApiResponse<DeliveryRequestsResponse>>(
        endpoints.requests.list,
        { query: { page: 1, pageSize: 50 } },
      );
      const data = unwrapApiResponse(response);
      setRequests((Array.isArray(data?.requests) ? data.requests : []).sort((a, b) => b.id - a.id));
      setShowModal(false);
      setFormDestination('');
      setFormResource('');
      setFormQty('');
      setFormPriority('normal');
      setFormArriveTill('');
    } catch (caught) {
      setFormError(caught instanceof Error ? caught.message : 'Failed to create request');
    } finally {
      setIsSubmitting(false);
    }
  }

  const canCreate = Boolean(user);

  const selectClass =
    'w-full rounded-xl border border-border bg-surface px-3 py-2 text-sm text-text focus:outline-none focus:ring-2 focus:ring-primary/60';

  return (
    <div className="space-y-5 animate-slide-up">
      <div className="flex items-center justify-between gap-3">
        <p className="text-sm text-text-muted">
          {isLoading ? 'Loading…' : `${requests.length} request${requests.length === 1 ? '' : 's'} total`}
        </p>
        {canCreate ? (
          <Button size="sm" onClick={() => setShowModal(true)}>
            <Plus size={15} className="mr-1.5" />
            New request
          </Button>
        ) : null}
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Delivery requests</CardTitle>
        </CardHeader>
        <CardContent>
          {/* Mobile */}
          <div className="space-y-3 lg:hidden">
            {isLoading ? (
              Array.from({ length: 4 }).map((_, i) => (
                <div key={i} className="rounded-xl border border-border bg-surface/50 p-4">
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0 space-y-1.5">
                      <Skeleton className="h-4 w-28" />
                      <Skeleton className="h-3 w-36" />
                    </div>
                    <div className="flex shrink-0 flex-col items-end gap-1.5">
                      <Skeleton className="h-5 w-16" />
                      <Skeleton className="h-5 w-16" />
                    </div>
                  </div>
                  <div className="mt-3 grid grid-cols-2 gap-2">
                    {Array.from({ length: 3 }).map((__, j) => (
                      <div key={j}>
                        <Skeleton className="h-3 w-12 mb-1" />
                        <Skeleton className="h-4 w-20" />
                      </div>
                    ))}
                  </div>
                </div>
              ))
            ) : error ? (
              <p className="py-10 text-center text-sm text-danger">{error}</p>
            ) : displayedRequests.length === 0 ? (
              <p className="py-10 text-center text-sm text-text-muted">No delivery requests found.</p>
            ) : (
              displayedRequests.map((req) => (
                <div key={req.id} className="rounded-xl border border-border bg-surface/50 p-4">
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <p className="text-sm font-semibold text-text">Request #{req.id}</p>
                      <p className="mt-0.5 truncate text-xs text-text-muted">{destinationLabel(req.destination_id)}</p>
                    </div>
                    <div className="flex shrink-0 flex-col items-end gap-1.5">
                      <Badge tone={priorityTone(req.priority)}>{req.priority}</Badge>
                      <Badge tone={statusTone(req.status)}>{statusLabel(req.status)}</Badge>
                    </div>
                  </div>
                  <div className="mt-3 grid grid-cols-2 gap-2 text-xs">
                    <div><p className="text-text-muted">Quantity</p><p className="mt-0.5 text-text">{req.quantity}</p></div>
                    <div><p className="text-text-muted">ETA</p><p className="mt-0.5 text-text">{req.arrive_till ? formatRelativeCountdown(req.arrive_till) : 'N/A'}</p></div>
                    <div><p className="text-text-muted">Created</p><p className="mt-0.5 text-text">{formatDateTime(req.created_at)}</p></div>
                  </div>
                </div>
              ))
            )}
          </div>

          {/* Desktop */}
          <div className="hidden lg:block">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>ID</TableHead>
                  <TableHead>Destination</TableHead>
                  <TableHead>Priority</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Items</TableHead>
                  <TableHead
                    className="cursor-pointer select-none hover:text-text"
                    onClick={() => toggleSort('quantity')}
                  >
                    Quantity <SortIcon active={sortKey === 'quantity'} dir={sortDir} />
                  </TableHead>
                  <TableHead>ETA</TableHead>
                  <TableHead className="text-right">Created</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  Array.from({ length: 6 }).map((_, i) => (
                    <SkeletonRow key={i} cols={['w-8', 'w-32', 'w-16', 'w-20', 'w-8', 'w-12', 'w-20', 'w-24']} />
                  ))
                ) : error ? (
                  <TableRow><TableCell className="py-10 text-center text-danger" colSpan={8}>{error}</TableCell></TableRow>
                ) : displayedRequests.length === 0 ? (
                  <TableRow><TableCell className="py-10 text-center text-text-muted" colSpan={8}>No delivery requests found.</TableCell></TableRow>
                ) : (
                  displayedRequests.map((req) => (
                    <TableRow key={req.id} className="hover:bg-accent/60">
                      <TableCell className="font-medium text-text">#{req.id}</TableCell>
                      <TableCell className="text-text-muted">{destinationLabel(req.destination_id)}</TableCell>
                      <TableCell><Badge tone={priorityTone(req.priority)}>{req.priority}</Badge></TableCell>
                      <TableCell><Badge tone={statusTone(req.status)}>{statusLabel(req.status)}</Badge></TableCell>
                      <TableCell className="text-text-muted">{req.items ? req.items.length : 1}</TableCell>
                      <TableCell className="text-text-muted">{req.quantity}</TableCell>
                      <TableCell className="text-text-muted">{req.arrive_till ? formatRelativeCountdown(req.arrive_till) : 'N/A'}</TableCell>
                      <TableCell className="text-right text-text-muted">{formatDateTime(req.created_at)}</TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      {/* New Request Modal */}
      {showModal ? (
        <div className="fixed inset-0 z-[3000] flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setShowModal(false)} />
          <div className="relative w-full max-w-md rounded-2xl border border-border bg-surface shadow-card animate-slide-up">
            <div className="flex items-center justify-between border-b border-border px-5 py-4">
              <h2 className="text-base font-semibold text-text">New delivery request</h2>
              <button
                type="button"
                onClick={() => setShowModal(false)}
                className="flex h-7 w-7 items-center justify-center rounded-lg text-text-muted hover:bg-accent hover:text-text"
              >
                <X size={16} />
              </button>
            </div>

            <form onSubmit={(e) => void handleSubmit(e)} className="space-y-4 px-5 py-4">
              <div>
                <label className="mb-1.5 block text-xs text-text-muted">Destination</label>
                <select
                  className={selectClass}
                  value={formDestination}
                  onChange={(e) => setFormDestination(e.target.value)}
                  required
                >
                  <option value="">Select destination…</option>
                  {customerPoints.map((p) => (
                    <option key={p.id} value={p.id}>{p.name} (#{p.id})</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="mb-1.5 block text-xs text-text-muted">Resource</label>
                <select
                  className={selectClass}
                  value={formResource}
                  onChange={(e) => setFormResource(e.target.value)}
                  required
                >
                  <option value="">Select resource…</option>
                  {resourceItems.map((r) => (
                    <option key={r.resourceId} value={r.resourceId}>{r.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="mb-1.5 block text-xs text-text-muted">Quantity</label>
                <Input
                  type="number"
                  min="1"
                  placeholder="e.g. 50"
                  value={formQty}
                  onChange={(e) => setFormQty(e.target.value)}
                  required
                />
              </div>

              <div>
                <label className="mb-1.5 block text-xs text-text-muted">Priority</label>
                <select
                  className={selectClass}
                  value={formPriority}
                  onChange={(e) => setFormPriority(e.target.value as DeliveryPriority)}
                >
                  {PRIORITIES.map((p) => (
                    <option key={p} value={p}>{p.charAt(0).toUpperCase() + p.slice(1)}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="mb-1.5 block text-xs text-text-muted">Arrive by (optional)</label>
                <input
                  type="datetime-local"
                  className={selectClass}
                  value={formArriveTill}
                  onChange={(e) => setFormArriveTill(e.target.value)}
                />
              </div>

              {formError ? (
                <p className="text-sm text-danger">{formError}</p>
              ) : null}

              <div className="flex gap-2 pt-1">
                <Button type="button" variant="ghost" size="sm" onClick={() => setShowModal(false)} className="flex-1">
                  Cancel
                </Button>
                <Button type="submit" size="sm" disabled={isSubmitting} className="flex-1">
                  {isSubmitting ? 'Creating…' : 'Create request'}
                </Button>
              </div>
            </form>
          </div>
        </div>
      ) : null}
    </div>
  );
}
