import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { useEffect, useMemo, useRef, useState } from 'react';
import { MapContainer, TileLayer, useMap as useLeafletMap } from 'react-leaflet';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { useInventory } from '@/features/inventory/hooks/useInventory';
import { useMap } from '@/features/map/hooks/useMap';
import type { MapPoint, MapPointStatus } from '@/shared/api';
import { formatNumber, mapStatusTone } from '@/shared/lib/formatters';
import { Badge } from '@/shared/ui/Badge';

const STATUS_COLOR: Record<MapPointStatus, string> = {
  normal: '#22c55e',
  elevated: '#f59e0b',
  critical: '#ef4444',
  predictive: '#8b5cf6',
};

const DEFAULT_CENTER: [number, number] = [49.8397, 24.0297];
const DEFAULT_ZOOM = 10;

type Filter = 'all' | MapPointStatus;

function makeIcon(status: MapPointStatus, type: 'warehouse' | 'customer') {
  const color = STATUS_COLOR[status];
  const size = type === 'warehouse' ? 18 : 14;
  const pulse =
    status === 'critical'
      ? 'map-marker--pulse-fast'
      : status === 'elevated'
        ? 'map-marker--pulse-slow'
        : '';

  return L.divIcon({
    html: `<span class="map-marker ${pulse}" style="background:${color};width:${size}px;height:${size}px;border-radius:50%;display:block;border:2px solid rgba(255,255,255,0.6);box-shadow:0 0 6px ${color}80"></span>`,
    className: '',
    iconSize: [size, size],
    iconAnchor: [size / 2, size / 2],
  });
}

function MarkersLayer({
  points,
  onSelect,
}: {
  points: MapPoint[];
  onSelect: (point: MapPoint | null) => void;
}) {
  const map = useLeafletMap();
  const layerRef = useRef<L.LayerGroup | null>(null);

  useEffect(() => {
    if (layerRef.current) {
      layerRef.current.clearLayers();
    } else {
      layerRef.current = L.layerGroup().addTo(map);
    }

    points.forEach((point) => {
      const marker = L.marker([point.lat, point.lng], {
        icon: makeIcon(point.status, point.type),
      });

      marker.on('click', () => onSelect(point));
      layerRef.current?.addLayer(marker);
    });

    return () => {
      layerRef.current?.clearLayers();
    };
  }, [map, onSelect, points]);

  return null;
}

function FilterBar({
  active,
  onChange,
}: {
  active: Filter;
  onChange: (filter: Filter) => void;
}) {
  const filters: Filter[] = ['all', 'critical', 'elevated', 'predictive', 'normal'];

  return (
    <div className="absolute left-4 top-4 z-[1000] flex gap-1.5 rounded-xl border border-border bg-background/90 p-1.5 shadow backdrop-blur">
      {filters.map((filter) => (
        <button
          key={filter}
          onClick={() => onChange(filter)}
          className={`rounded-lg px-3 py-1 text-xs font-medium capitalize transition-colors ${
            active === filter
              ? 'bg-primary text-background'
              : 'text-text-muted hover:bg-white/5 hover:text-text'
          }`}
        >
          {filter}
        </button>
      ))}
    </div>
  );
}

type SidePanelProps = {
  point: MapPoint;
  nearestStock: Array<{
    warehouse_id: number;
    warehouse_name: string;
    surplus: number;
    distance_km: number;
    estimated_arrival_hours: number;
  }>;
  isNearestStockLoading: boolean;
  resourceSelected: boolean;
  needed: number;
  onClose: () => void;
};

function SidePanel({
  point,
  nearestStock,
  isNearestStockLoading,
  resourceSelected,
  needed,
  onClose,
}: SidePanelProps) {
  return (
    <div className="absolute right-4 top-4 z-[1000] w-72 rounded-xl border border-border bg-background/95 p-4 shadow-xl backdrop-blur">
      <div className="mb-3 flex items-start justify-between gap-2">
        <div>
          <p className="font-semibold text-text">{point.name}</p>
          <p className="text-xs capitalize text-text-muted">{point.type}</p>
        </div>
        <button
          onClick={onClose}
          className="text-text-muted transition-colors hover:text-text"
          aria-label="Close"
        >
          x
        </button>
      </div>

      <div className="mb-3 flex items-center gap-2">
        <Badge tone={mapStatusTone(point.status)} className="capitalize">
          {point.status}
        </Badge>
        {point.alert_count > 0 ? (
          <span className="text-xs text-text-muted">
            {point.alert_count} open alert{point.alert_count !== 1 ? 's' : ''}
          </span>
        ) : null}
      </div>

      <div className="space-y-1 text-sm text-text-muted">
        <p>
          <span className="text-text-muted/60">Lat: </span>
          {point.lat.toFixed(5)}
        </p>
        <p>
          <span className="text-text-muted/60">Lng: </span>
          {point.lng.toFixed(5)}
        </p>
      </div>

      {point.type === 'customer' ? (
        <div className="mt-4 border-t border-border pt-4">
          <p className="text-xs uppercase tracking-[0.18em] text-text-muted">
            Nearest stock
          </p>
          {!resourceSelected ? (
            <p className="mt-2 text-sm text-text-muted">
              Select a resource to rank nearby warehouses.
            </p>
          ) : isNearestStockLoading ? (
            <p className="mt-2 text-sm text-text-muted">Loading nearest stock…</p>
          ) : nearestStock.length === 0 ? (
            <p className="mt-2 text-sm text-text-muted">
              No warehouse can supply {formatNumber(needed)} units while holding
              the 20% safety stock.
            </p>
          ) : (
            <div className="mt-3 space-y-2">
              {nearestStock.map((entry) => (
                <div
                  key={entry.warehouse_id}
                  className="rounded-xl border border-border bg-surface/50 p-3"
                >
                  <p className="text-sm font-medium">{entry.warehouse_name}</p>
                  <p className="mt-1 text-xs text-text-muted">
                    {formatNumber(entry.surplus)} surplus ·{' '}
                    {formatNumber(entry.distance_km)} km ·{' '}
                    {formatNumber(entry.estimated_arrival_hours)}h ETA
                  </p>
                </div>
              ))}
            </div>
          )}
        </div>
      ) : null}
    </div>
  );
}

type MapViewProps = {
  compact?: boolean;
};

export function MapView({ compact = false }: MapViewProps) {
  const { user } = useAuth();
  const [selected, setSelected] = useState<MapPoint | null>(null);
  const [selectedResourceId, setSelectedResourceId] = useState<number | undefined>();
  const [needed, setNeeded] = useState(100);
  const [filter, setFilter] = useState<Filter>('all');

  const { items } = useInventory({
    enabled: Boolean(user?.location_id),
    locationId: user?.location_id ?? 0,
    page: 1,
    pageSize: 50,
  });

  const resourceOptions = useMemo(
    () =>
      [...items]
        .sort((left, right) => left.name.localeCompare(right.name))
        .map((item) => ({
          id: item.resourceId,
          name: item.name,
        })),
    [items],
  );

  const { points, nearestStock, isLoading, isNearestStockLoading, error } = useMap({
    resourceId: selected?.type === 'customer' ? selectedResourceId : undefined,
    pointId: selected?.type === 'customer' ? selected.id : undefined,
    needed,
  });

  useEffect(() => {
    if (!selectedResourceId && resourceOptions.length > 0) {
      setSelectedResourceId(resourceOptions[0].id);
    }
  }, [resourceOptions, selectedResourceId]);

  const visiblePoints =
    filter === 'all' ? points : points.filter((point) => point.status === filter);

  return (
    <div className="relative h-full w-full overflow-hidden rounded-xl border border-border">
      {isLoading && points.length === 0 ? (
        <div className="absolute inset-0 z-[2000] flex items-center justify-center bg-background/80">
          <span className="text-sm text-text-muted">Loading map…</span>
        </div>
      ) : null}

      {error ? (
        <div className="absolute bottom-4 left-4 z-[1000] rounded-xl border border-danger/20 bg-background/95 px-3 py-2 text-sm text-danger shadow-lg">
          {error}
        </div>
      ) : null}

      <FilterBar active={filter} onChange={setFilter} />

      <div className="absolute left-4 top-16 z-[1000] flex w-[min(28rem,calc(100%-2rem))] flex-wrap gap-2 rounded-xl border border-border bg-background/90 p-3 shadow backdrop-blur">
        <select
          className="h-10 min-w-[12rem] rounded-xl border border-border bg-surface/80 px-3 text-sm text-text outline-none"
          value={selectedResourceId ?? ''}
          onChange={(event) => {
            setSelectedResourceId(
              event.target.value === '' ? undefined : Number(event.target.value),
            );
          }}
        >
          {resourceOptions.map((option) => (
            <option key={option.id} value={option.id}>
              {option.name}
            </option>
          ))}
        </select>

        <input
          className="h-10 w-28 rounded-xl border border-border bg-surface/80 px-3 text-sm text-text outline-none"
          min={1}
          step={1}
          type="number"
          value={needed}
          onChange={(event) => setNeeded(Number(event.target.value) || 0)}
        />

        {!compact ? (
          <p className="flex items-center text-xs text-text-muted">
            Click a customer point to evaluate the nearest warehouses with surplus
            stock after the 20% safety reserve.
          </p>
        ) : null}
      </div>

      {selected ? (
        <SidePanel
          point={selected}
          nearestStock={nearestStock}
          isNearestStockLoading={isNearestStockLoading}
          resourceSelected={Boolean(selectedResourceId)}
          needed={needed}
          onClose={() => setSelected(null)}
        />
      ) : null}

      <MapContainer
        center={DEFAULT_CENTER}
        zoom={DEFAULT_ZOOM}
        style={{ height: '100%', width: '100%' }}
        zoomControl={false}
      >
        <TileLayer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        />
        <MarkersLayer points={visiblePoints} onSelect={setSelected} />
      </MapContainer>
    </div>
  );
}
