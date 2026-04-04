import { MapView } from '@/features/map/MapView';

export function MapPage() {
  return (
    <div className="flex h-full flex-col gap-4 p-6">
      <div>
        <h1 className="text-xl font-semibold text-text">Live Map</h1>
        <p className="text-sm text-text-muted">
          Warehouses and delivery points — colour-coded by status. Refreshes every 30 s.
        </p>
      </div>
      <div className="min-h-0 flex-1">
        <MapView />
      </div>
    </div>
  );
}
