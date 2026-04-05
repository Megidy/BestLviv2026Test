import { useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { useNetwork } from '@/shared/hooks/useNetwork';
import { useInventory } from '@/features/inventory/hooks/useInventory';
import { useMap } from '@/features/map/hooks/useMap';
import { useNearestStock } from '@/features/map/useNearestStock';
import { useRequests } from '@/features/requests/hooks/useRequests';
import type { DeliveryPriority } from '@/shared/api';
import {
  formatDateTime,
  formatNumber,
  priorityTone,
} from '@/shared/lib/formatters';
import { Badge } from '@/shared/ui/Badge';
import { Button } from '@/shared/ui/Button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/shared/ui/Card';
import { Input } from '@/shared/ui/Input';
import { ResourcePanel } from '@/widgets/ResourcePanel';

export function ResourceModule() {
  const { id } = useParams();
  const { user } = useAuth();
  const { isOnline } = useNetwork();
  const resourceId = Number(id);
  const [selectedCustomerId, setSelectedCustomerId] = useState<number | undefined>();
  const [requestQuantity, setRequestQuantity] = useState(100);
  const [requestPriority, setRequestPriority] =
    useState<DeliveryPriority>('normal');
  const [arriveTill, setArriveTill] = useState('');
  const [demandQuantity, setDemandQuantity] = useState(50);
  const [editQuantities, setEditQuantities] = useState<Record<number, number>>({});

  const { items, isLoading, error } = useInventory({
    enabled: Boolean(user?.location_id),
    locationId: user?.location_id ?? 0,
    page: 1,
    pageSize: 50,
  });

  const resource = useMemo(
    () => items.find((item) => item.resourceId === resourceId),
    [items, resourceId],
  );

  const { points, error: mapError } = useMap();
  const {
    data: nearestStock,
    isLoading: isNearestStockLoading,
    error: nearestStockError,
  } = useNearestStock({
    resourceId: resource?.resourceId,
    customerId: selectedCustomerId,
    needed: requestQuantity,
    enabled: Boolean(resource && selectedCustomerId),
  });

  const customers = useMemo(
    () => points.filter((point) => point.type === 'customer'),
    [points],
  );

  const pointNameById = useMemo(
    () => Object.fromEntries(points.map((point) => [point.id, point.name])),
    [points],
  );

  const {
    requests,
    demandReadings,
    isLoading: requestsLoading,
    isMutating,
    error: requestsError,
    createRequest,
    allocatePending,
    updateQuantity,
    escalate,
    approveAllocation,
    dispatchAllocation,
    deliver,
    recordDemand,
  } = useRequests({
    resourceId: resource?.resourceId,
    pointId: selectedCustomerId,
    page: 1,
    pageSize: 20,
    enabled: Boolean(resource),
  });

  if (isLoading) {
    return <p className="text-sm text-text-muted">Loading resource…</p>;
  }

  if (error || !resource) {
    return (
      <p className="text-sm text-danger">
        {error ?? 'This resource is not available for the current warehouse.'}
      </p>
    );
  }

  return (
    <div className="space-y-5 animate-slide-up">
      <div className="flex items-center justify-between gap-4">
        <div>
          <p className="text-xs uppercase tracking-[0.2em] text-text-muted">
            Resource
          </p>
          <h1 className="mt-2 text-2xl font-semibold">{resource.name}</h1>
          <p className="mt-1 text-sm text-text-muted">
            Updated at {formatDateTime(resource.updatedAt)}
          </p>
        </div>
        <Badge tone="info">{resource.category}</Badge>
      </div>

      <div className="grid gap-5 xl:grid-cols-[minmax(0,2fr)_minmax(320px,1fr)]">
        <div className="space-y-5">
          <Card>
            <CardHeader>
              <CardTitle>Current stock</CardTitle>
              <CardDescription>
                Real-time operational state of this resource.
              </CardDescription>
            </CardHeader>
            <CardContent className="grid gap-4 md:grid-cols-2">
              <div className="rounded-xl border border-border bg-surface/60 p-4 transition-colors hover:bg-accent/40">
                <p className="text-sm text-text-muted">Quantity</p>
                <p className="mt-2 text-3xl font-semibold">
                  {formatNumber(resource.quantity)} {resource.unit}
                </p>
              </div>
              <div className="rounded-xl border border-border bg-surface/60 p-4 transition-colors hover:bg-accent/40">
                <p className="text-sm text-text-muted">Warehouse</p>
                <p className="mt-2 text-xl font-semibold">#{resource.locationId}</p>
              </div>
              <div className="rounded-xl border border-border bg-surface/60 p-4 transition-colors hover:bg-accent/40">
                <p className="text-sm text-text-muted">Safety stock</p>
                <p className="mt-2 text-xl font-semibold">
                  {formatNumber(resource.safetyStock)} {resource.unit}
                </p>
              </div>
              <div className="rounded-xl border border-border bg-surface/60 p-4 transition-colors hover:bg-accent/40">
                <p className="text-sm text-text-muted">Available to allocate</p>
                <p className="mt-2 text-xl font-semibold">
                  {formatNumber(resource.allocatableQuantity)} {resource.unit}
                </p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Delivery request flow</CardTitle>
              <CardDescription>
                Urgent requests require an arrival deadline and are auto-allocated
                immediately by the backend.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <label className="text-sm text-text-muted">Destination</label>
                  <select
                    className="h-10 w-full rounded-xl border border-border bg-surface/80 px-3 text-sm text-text outline-none"
                    value={selectedCustomerId ?? ''}
                    onChange={(event) => {
                      setSelectedCustomerId(
                        event.target.value === ''
                          ? undefined
                          : Number(event.target.value),
                      );
                    }}
                  >
                    <option value="">Select customer</option>
                    {customers.map((customer) => (
                      <option key={customer.id} value={customer.id}>
                        {customer.name}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="text-sm text-text-muted">Quantity</label>
                  <Input
                    min={1}
                    step={1}
                    type="number"
                    value={requestQuantity}
                    onChange={(event) =>
                      setRequestQuantity(Number(event.target.value) || 0)
                    }
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm text-text-muted">Priority</label>
                  <select
                    className="h-10 w-full rounded-xl border border-border bg-surface/80 px-3 text-sm text-text outline-none"
                    value={requestPriority}
                    onChange={(event) =>
                      setRequestPriority(event.target.value as DeliveryPriority)
                    }
                  >
                    <option value="normal">Normal</option>
                    <option value="elevated">Elevated</option>
                    <option value="critical">Critical</option>
                    <option value="urgent">Urgent</option>
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="text-sm text-text-muted">Arrive till</label>
                  <Input
                    type="datetime-local"
                    value={arriveTill}
                    onChange={(event) => setArriveTill(event.target.value)}
                  />
                </div>
              </div>

              <div className="flex flex-wrap gap-3">
                <Button
                  disabled={isMutating || !isOnline || !selectedCustomerId || requestQuantity <= 0}
                  title={!isOnline ? 'Not available offline' : undefined}
                  onClick={async () => {
                    if (requestPriority === 'urgent' && !arriveTill) {
                      return;
                    }

                    await createRequest({
                      destination_id: selectedCustomerId!,
                      priority: requestPriority,
                      arrive_till:
                        requestPriority === 'urgent' && arriveTill
                          ? new Date(arriveTill).toISOString()
                          : undefined,
                      items: [
                        {
                          resource_id: resource.resourceId,
                          quantity: requestQuantity,
                        },
                      ],
                    });
                  }}
                >
                  Create request
                </Button>
                {user?.role === 'dispatcher' || user?.role === 'admin' ? (
                  <Button
                    variant="outline"
                    disabled={isMutating || !isOnline}
                    title={!isOnline ? 'Not available offline' : undefined}
                    onClick={() => void allocatePending()}
                  >
                    Run allocation queue
                  </Button>
                ) : null}
                <Button asChild variant="ghost">
                  <Link to="/inventory">Back to inventory</Link>
                </Button>
              </div>

              {requestPriority === 'urgent' && !arriveTill ? (
                <p className="text-sm text-warning">
                  Urgent requests must include `arrive_till`.
                </p>
              ) : null}
              <p className="text-sm text-text-muted">
                Safety stock is fixed at 20%, so nearest-stock and allocation
                calculations reserve part of each warehouse inventory.
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Demand readings</CardTitle>
              <CardDescription>
                Post manual demand and review the latest history for the selected
                delivery point.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex flex-wrap items-end gap-3">
                <div className="min-w-[12rem] flex-1 space-y-2">
                  <label className="text-sm text-text-muted">Delivery point</label>
                  <select
                    className="h-10 w-full rounded-xl border border-border bg-surface/80 px-3 text-sm text-text outline-none"
                    value={selectedCustomerId ?? ''}
                    onChange={(event) => {
                      setSelectedCustomerId(
                        event.target.value === ''
                          ? undefined
                          : Number(event.target.value),
                      );
                    }}
                  >
                    <option value="">Select customer</option>
                    {customers.map((customer) => (
                      <option key={customer.id} value={customer.id}>
                        {customer.name}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="w-36 space-y-2">
                  <label className="text-sm text-text-muted">Demand qty</label>
                  <Input
                    type="number"
                    min={1}
                    value={demandQuantity}
                    onChange={(event) =>
                      setDemandQuantity(Number(event.target.value) || 0)
                    }
                  />
                </div>
                <Button
                  disabled={isMutating || !isOnline || !selectedCustomerId || demandQuantity <= 0}
                  title={!isOnline ? 'Not available offline' : undefined}
                  onClick={() =>
                    void recordDemand({
                      point_id: selectedCustomerId!,
                      resource_id: resource.resourceId,
                      quantity: demandQuantity,
                      source: 'manual',
                    })
                  }
                >
                  Record demand
                </Button>
              </div>

              {selectedCustomerId ? (
                demandReadings.length > 0 ? (
                  <div className="space-y-3">
                    <div className="flex h-36 items-end gap-2 rounded-xl border border-border bg-surface/40 p-4">
                      {demandReadings
                        .slice()
                        .reverse()
                        .map((reading) => {
                          const maxQuantity = Math.max(
                            ...demandReadings.map((entry) => entry.quantity),
                            1,
                          );
                          const height = `${(reading.quantity / maxQuantity) * 100}%`;

                          return (
                            <div
                              key={reading.id}
                              className="flex flex-1 flex-col items-center justify-end gap-2"
                            >
                              <div
                                className="w-full rounded-t-md bg-primary/80"
                                style={{ height }}
                              />
                              <span className="text-[10px] text-text-muted">
                                {reading.quantity}
                              </span>
                            </div>
                          );
                        })}
                    </div>
                    <div className="space-y-1">
                      {demandReadings.map((reading) => (
                        <p key={reading.id} className="text-xs text-text-muted">
                          {formatDateTime(reading.recorded_at)} · {reading.quantity}{' '}
                          {resource.unit}
                        </p>
                      ))}
                    </div>
                  </div>
                ) : (
                  <p className="text-sm text-text-muted">
                    No demand history for the selected point yet.
                  </p>
                )
              ) : (
                <p className="text-sm text-text-muted">
                  Select a delivery point to load demand history.
                </p>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Requests and allocations</CardTitle>
              <CardDescription>
                Quantity increases above 1.5x on pending requests auto-escalate
                priority by one level.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {requestsLoading ? (
                <p className="text-sm text-text-muted">Loading requests…</p>
              ) : requestsError ? (
                <p className="text-sm text-danger">{requestsError}</p>
              ) : requests.length === 0 ? (
                <p className="text-sm text-text-muted">
                  No delivery requests for this resource yet.
                </p>
              ) : (
                requests.map((requestItem) => {
                  const relatedItem =
                    requestItem.items?.find(
                      (item) => item.resource_id === resource.resourceId,
                    ) ?? requestItem.items?.[0];
                  const editValue =
                    editQuantities[requestItem.id] ?? relatedItem?.quantity ?? 0;

                  return (
                    <div
                      key={requestItem.id}
                      className="rounded-2xl border border-border bg-surface/40 p-4"
                    >
                      <div className="flex flex-wrap items-start justify-between gap-3">
                        <div>
                          <p className="text-sm font-semibold">
                            Request #{requestItem.id}
                          </p>
                          <p className="mt-1 text-xs text-text-muted">
                            {pointNameById[requestItem.destination_id] ??
                              `Point #${requestItem.destination_id}`}{' '}
                            · {formatDateTime(requestItem.created_at)}
                          </p>
                        </div>
                        <div className="flex flex-wrap gap-2">
                          <Badge tone={priorityTone(requestItem.priority)}>
                            {requestItem.priority}
                          </Badge>
                          <Badge tone="neutral">{requestItem.status}</Badge>
                        </div>
                      </div>

                      <div className="mt-4 grid gap-3 md:grid-cols-[minmax(0,1fr)_auto]">
                        <div className="space-y-2">
                          <p className="text-sm text-text-muted">
                            Requested quantity:{' '}
                            {relatedItem?.quantity ?? requestItem.quantity}{' '}
                            {resource.unit}
                          </p>
                          {requestItem.status === 'pending' && relatedItem ? (
                            <div className="flex flex-wrap items-center gap-2">
                              <Input
                                className="w-40"
                                type="number"
                                min={1}
                                value={editValue}
                                onChange={(event) =>
                                  setEditQuantities((current) => ({
                                    ...current,
                                    [requestItem.id]:
                                      Number(event.target.value) || 0,
                                  }))
                                }
                              />
                              <Button
                                size="sm"
                                variant="outline"
                                disabled={isMutating || !isOnline || editValue <= 0}
                                title={!isOnline ? 'Not available offline' : undefined}
                                onClick={() =>
                                  void updateQuantity(
                                    requestItem.id,
                                    relatedItem.resource_id,
                                    editValue,
                                  )
                                }
                              >
                                Update quantity
                              </Button>
                              <Button
                                size="sm"
                                variant="ghost"
                                disabled={isMutating || !isOnline}
                                title={!isOnline ? 'Not available offline' : undefined}
                                onClick={() => void escalate(requestItem.id)}
                              >
                                Escalate
                              </Button>
                            </div>
                          ) : null}
                        </div>

                        {requestItem.status === 'in_transit' ? (
                          <Button
                            size="sm"
                            disabled={isMutating || !isOnline}
                            title={!isOnline ? 'Not available offline' : undefined}
                            onClick={() => void deliver(requestItem.id)}
                          >
                            Confirm delivery
                          </Button>
                        ) : null}
                      </div>

                      <div className="mt-4 space-y-2">
                        <p className="text-sm font-medium">Allocations</p>
                        {(requestItem.allocations ?? []).length === 0 ? (
                          <p className="text-sm text-text-muted">
                            No allocations created yet.
                          </p>
                        ) : (
                          requestItem.allocations?.map((allocation) => (
                            <div
                              key={allocation.id}
                              className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-border bg-background/40 p-3"
                            >
                              <div>
                                <p className="text-sm font-medium">
                                  Warehouse #{allocation.source_warehouse_id}
                                </p>
                                <p className="mt-1 text-xs text-text-muted">
                                  {allocation.quantity} {resource.unit} ·{' '}
                                  {allocation.status}
                                </p>
                              </div>
                              <div className="flex gap-2">
                                {allocation.status === 'planned' &&
                                (user?.role === 'dispatcher' ||
                                  user?.role === 'admin') ? (
                                  <Button
                                    size="sm"
                                    variant="ghost"
                                    disabled={isMutating || !isOnline}
                                    title={!isOnline ? 'Not available offline' : undefined}
                                    onClick={() =>
                                      void approveAllocation(allocation.id)
                                    }
                                  >
                                    Approve
                                  </Button>
                                ) : null}
                                {allocation.status === 'approved' ? (
                                  <Button
                                    size="sm"
                                    variant="outline"
                                    disabled={isMutating || !isOnline}
                                    title={!isOnline ? 'Not available offline' : undefined}
                                    onClick={() =>
                                      void dispatchAllocation(allocation.id)
                                    }
                                  >
                                    Dispatch
                                  </Button>
                                ) : null}
                              </div>
                            </div>
                          ))
                        )}
                      </div>
                    </div>
                  );
                })
              )}
            </CardContent>
          </Card>
        </div>

        <div className="space-y-5">
          <ResourcePanel
            variant="nearest-stock"
            items={nearestStock.map((item) => ({
              warehouseId: item.warehouse_id,
              warehouseName: item.warehouse_name,
              surplus: item.surplus,
              distanceKm: item.distance_km,
              estimatedArrivalHours: item.estimated_arrival_hours,
            }))}
          />

          <Card>
            <CardHeader>
              <CardTitle>Operational notes</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="rounded-xl border border-border bg-surface/60 p-4">
                <p className="text-sm font-medium">Safety stock</p>
                <p className="mt-1 text-xs text-text-muted">
                  Allocation and nearest-stock ranking hold back 20% of every
                  warehouse quantity as protected reserve.
                </p>
              </div>
              <div className="rounded-xl border border-border bg-surface/60 p-4">
                <p className="text-sm font-medium">Priority escalation</p>
                <p className="mt-1 text-xs text-text-muted">
                  Updating a pending request above 1.5x its previous quantity
                  automatically escalates priority one step on the backend.
                </p>
              </div>
              {isNearestStockLoading ? (
                <p className="text-xs text-text-muted">Calculating nearest stock…</p>
              ) : null}
              {nearestStockError || mapError ? (
                <p className="text-xs text-danger">{nearestStockError ?? mapError}</p>
              ) : null}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
