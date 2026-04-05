import { useState, useEffect, useMemo } from 'react';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { useInventory } from '@/features/inventory/hooks/useInventory';
import { MapView, ControlPanel } from '@/features/map/MapView';
import type { StatusFilter, TypeFilter } from '@/features/map/MapView';

export function MapPage() {
  const { user } = useAuth();

  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [typeFilter, setTypeFilter] = useState<TypeFilter>('customer');
  const [selectedResourceId, setSelectedResourceId] = useState<number | undefined>();
  const [neededQty, setNeededQty] = useState(100);

  const { items } = useInventory({
    enabled: Boolean(user?.location_id),
    locationId: user?.location_id ?? 0,
    page: 1,
    pageSize: 50,
  });

  const resourceOptions = useMemo(
    () => [...items].sort((a, b) => a.name.localeCompare(b.name)).map(i => ({ id: i.resourceId, name: i.name })),
    [items],
  );

  // Auto-select first resource when options load
  useEffect(() => {
    if (!selectedResourceId && resourceOptions.length > 0) setSelectedResourceId(resourceOptions[0].id);
  }, [resourceOptions, selectedResourceId]);

  return (
    <div className="flex h-full flex-col gap-3 animate-slide-up">
      <div>
        <h1 className="text-xl font-semibold text-text">Live Map</h1>
        <p className="text-sm text-text-muted">
          Warehouses and delivery points — colour-coded by status. Refreshes every 30 s.
        </p>
      </div>

      <ControlPanel
        statusFilter={statusFilter}
        setStatusFilter={setStatusFilter}
        typeFilter={typeFilter}
        setTypeFilter={setTypeFilter}
        resourceOptions={resourceOptions}
        selectedResourceId={selectedResourceId}
        setSelectedResourceId={setSelectedResourceId}
        neededQty={neededQty}
        setNeededQty={setNeededQty}
      />

      <div className="min-h-0 flex-1">
        <MapView
          statusFilter={statusFilter}
          typeFilter={typeFilter}
          selectedResourceId={selectedResourceId}
          neededQty={neededQty}
        />
      </div>
    </div>
  );
}
