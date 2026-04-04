import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { useEffect, useMemo, useRef, useState } from 'react';
import { MapContainer, TileLayer, useMap as useLeafletMap } from 'react-leaflet';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { useInventory } from '@/features/inventory/hooks/useInventory';
import { useMap } from '@/features/map/hooks/useMap';
import { useNearestStock } from '@/features/map/useNearestStock';
import type { MapPoint, MapPointStatus, NearestStockResult } from '@/shared/api';
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

type StockMarkerTone = 'good' | 'borderline' | 'critical';

function makeIcon(
  status: MapPointStatus,
  type: 'warehouse' | 'customer',
  highlightColor?: string,
) {
  const color = highlightColor ?? STATUS_COLOR[status];
  const size = type === 'warehouse' ? 18 : 14;
  const pulse =
    highlightColor
      ? 'map-marker--pulse-fast'
      : status === 'critical'
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

function getStockMarkerTone(
  result: NearestStockResult,
  needed: number,
): StockMarkerTone {
  if (result.surplus >= needed * 1.5) {
    return 'good';
  }

  if (result.surplus >= needed) {
    return 'borderline';
  }

  return 'critical';
}

function getStockMarkerColor(tone: StockMarkerTone) {
  switch (tone) {
    case 'borderline':
      return '#f59e0b';
    case 'critical':
      return '#ef4444';
    default:
      return '#22c55e';
  }
}

type RenderablePoint = {
  point: MapPoint;
  nearestStock?: NearestStockResult;
};

function MarkersLayer({
  points,
  selectedId,
  needed,
  onSelect,
}: {
  points: RenderablePoint[];
  selectedId?: number;
  needed: number;
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

    points.forEach(({ point, nearestStock }) => {
      const tone =
        nearestStock && point.type === 'warehouse'
          ? getStockMarkerTone(nearestStock, needed)
          : null;
      const marker = L.marker([point.lat, point.lng], {
        icon: makeIcon(
          point.status,
          point.type,
          tone ? getStockMarkerColor(tone) : undefined,
        ),
      });

      if (point.id === selectedId) {
        marker.setZIndexOffset(1_000);
      }

      if (nearestStock && point.type === 'warehouse') {
        marker.bindPopup(
          `
            <div style="min-width:180px">
              <strong>${nearestStock.warehouse_name}</strong><br/>
              Available: ${formatNumber(nearestStock.surplus)}<br/>
              Distance: ${formatNumber(nearestStock.distance_km)} km<br/>
              ETA: ${formatNumber(nearestStock.estimated_arrival_hours)} h
            </div>
          `,
        );
      }

      marker.on('click', () => onSelect(point));
      layerRef.current?.addLayer(marker);
    });

    return () => {
      layerRef.current?.clearLayers();
    };
  }, [map, needed, onSelect, points, selectedId]);

  return null;
}

function MapViewportController({
  defaultCenter,
  selectedPoint,
  resultPoints,
}: {
  defaultCenter: [number, number];
  selectedPoint: MapPoint | null;
  resultPoints: MapPoint[];
}) {
  const map = useLeafletMap();

  useEffect(() => {
    if (selectedPoint?.type === 'warehouse') {
      map.setView([selectedPoint.lat, selectedPoint.lng], Math.max(map.getZoom(), 11), {
        animate: true,
      });
      return;
    }

    if (resultPoints.length > 0) {
      const bounds = L.latLngBounds(
        resultPoints.map((point) => [point.lat, point.lng] as [number, number]),
      );
      map.fitBounds(bounds, {
        padding: [48, 48],
        maxZoom: 11,
        animate: true,
      });
      return;
    }

    if (selectedPoint) {
      map.setView([selectedPoint.lat, selectedPoint.lng], Math.max(map.getZoom(), 10), {
        animate: true,
      });
      return;
    }

    map.setView(defaultCenter, DEFAULT_ZOOM, { animate: true });
  }, [defaultCenter, map, resultPoints, selectedPoint]);

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
  selectedPoint: MapPoint;
  selectedCustomer: MapPoint | null;
  nearestStock: NearestStockResult[];
  isNearestStockLoading: boolean;
  resourceSelected: boolean;
  needed: number;
  stockByWarehouseId: Record<number, NearestStockResult>;
  onWarehouseSelect: (warehouseId: number) => void;
  onClose: () => void;
};

function SidePanel({
  selectedPoint,
  selectedCustomer,
  nearestStock,
  isNearestStockLoading,
  resourceSelected,
  needed,
  stockByWarehouseId,
  onWarehouseSelect,
  onClose,
}: SidePanelProps) {
  const selectedWarehouseStock =
    selectedPoint.type === 'warehouse'
      ? stockByWarehouseId[selectedPoint.id]
      : undefined;

  return (
    <div className="absolute right-4 top-4 z-[1000] w-72 rounded-xl border border-border bg-background/95 p-4 shadow-xl backdrop-blur">
      <div className="mb-3 flex items-start justify-between gap-2">
        <div>
          <p className="font-semibold text-text">{selectedPoint.name}</p>
          <p className="text-xs capitalize text-text-muted">{selectedPoint.type}</p>
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
        <Badge tone={mapStatusTone(selectedPoint.status)} className="capitalize">
          {selectedPoint.status}
        </Badge>
        {selectedPoint.alert_count > 0 ? (
          <span className="text-xs text-text-muted">
            {selectedPoint.alert_count} open alert
            {selectedPoint.alert_count !== 1 ? 's' : ''}
          </span>
        ) : null}
      </div>

      <div className="space-y-1 text-sm text-text-muted">
        <p>
          <span className="text-text-muted/60">Lat: </span>
          {selectedPoint.lat.toFixed(5)}
        </p>
        <p>
          <span className="text-text-muted/60">Lng: </span>
          {selectedPoint.lng.toFixed(5)}
        </p>
      </div>

      {selectedWarehouseStock ? (
        <div className="mt-4 border-t border-border pt-4">
          <p className="text-xs uppercase tracking-[0.18em] text-text-muted">
            Stock insight
          </p>
          <div className="mt-3 space-y-2 rounded-xl border border-border bg-surface/50 p-3">
            <p className="text-sm font-medium text-text">
              {selectedWarehouseStock.warehouse_name}
            </p>
            <p className="text-xs text-text-muted">
              Available: {formatNumber(selectedWarehouseStock.surplus)}
            </p>
            <p className="text-xs text-text-muted">
              Distance: {formatNumber(selectedWarehouseStock.distance_km)} km
            </p>
            <p className="text-xs text-text-muted">
              ETA: {formatNumber(selectedWarehouseStock.estimated_arrival_hours)} h
            </p>
          </div>
        </div>
      ) : null}

      {selectedPoint.type === 'customer' ? (
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
              No stock available for {formatNumber(needed)} units with safety stock
              applied.
            </p>
          ) : (
            <div className="mt-3 space-y-2">
              {nearestStock.map((entry) => (
                <button
                  type="button"
                  key={entry.warehouse_id}
                  onClick={() => onWarehouseSelect(entry.warehouse_id)}
                  className="block w-full rounded-xl border border-border bg-surface/50 p-3 text-left transition-colors hover:border-primary/30 hover:bg-surface"
                >
                  <p className="text-sm font-medium">{entry.warehouse_name}</p>
                  <p className="mt-1 text-xs text-text-muted">
                    {formatNumber(entry.surplus)} available ·{' '}
                    {formatNumber(entry.distance_km)} km ·{' '}
                    {formatNumber(entry.estimated_arrival_hours)}h ETA
                  </p>
                </button>
              ))}
            </div>
          )}
        </div>
      ) : null}

      {selectedCustomer && selectedPoint.type === 'warehouse' ? (
        <p className="mt-4 text-xs text-text-muted">
          Serving {selectedCustomer.name} for {formatNumber(needed)} units.
        </p>
      ) : null}
    </div>
  );
}

type MapViewProps = {
  compact?: boolean;
};

export function MapView({ compact = false }: MapViewProps) {
  const { user } = useAuth();
  const [selectedPoint, setSelectedPoint] = useState<MapPoint | null>(null);
  const [selectedCustomer, setSelectedCustomer] = useState<MapPoint | null>(null);
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

  const { points, isLoading, error } = useMap();
  const {
    data: nearestStock,
    isLoading: isNearestStockLoading,
    error: nearestStockError,
  } = useNearestStock({
    resourceId: selectedResourceId,
    customerId: selectedCustomer?.id,
    needed,
    enabled: Boolean(selectedCustomer),
  });

  useEffect(() => {
    if (!selectedResourceId && resourceOptions.length > 0) {
      setSelectedResourceId(resourceOptions[0].id);
    }
  }, [resourceOptions, selectedResourceId]);

  const stockByWarehouseId = useMemo(
    () =>
      Object.fromEntries(nearestStock.map((entry) => [entry.warehouse_id, entry])),
    [nearestStock],
  );

  const warehousePointsById = useMemo(
    () =>
      Object.fromEntries(
        points
          .filter((point) => point.type === 'warehouse')
          .map((point) => [point.id, point]),
      ),
    [points],
  );

  const relevantWarehousePoints = useMemo(
    () =>
      nearestStock
        .map((entry) => warehousePointsById[entry.warehouse_id])
        .filter((point): point is MapPoint => Boolean(point)),
    [nearestStock, warehousePointsById],
  );

  const hasActiveNearestStockSearch = Boolean(
    selectedCustomer && selectedResourceId && needed > 0,
  );

  const filteredPoints = useMemo(
    () =>
      filter === 'all' ? points : points.filter((point) => point.status === filter),
    [filter, points],
  );

  const renderablePoints = useMemo(() => {
    if (hasActiveNearestStockSearch) {
      const customerEntry = selectedCustomer
        ? [{ point: selectedCustomer }]
        : [];

      return [
        ...customerEntry,
        ...relevantWarehousePoints.map((point) => ({
          point,
          nearestStock: stockByWarehouseId[point.id],
        })),
      ];
    }

    return filteredPoints.map((point) => ({ point }));
  }, [
    filteredPoints,
    hasActiveNearestStockSearch,
    relevantWarehousePoints,
    selectedCustomer,
    stockByWarehouseId,
  ]);

  const mapFocusPoints = useMemo(
    () =>
      selectedCustomer
        ? [selectedCustomer, ...relevantWarehousePoints]
        : relevantWarehousePoints,
    [relevantWarehousePoints, selectedCustomer],
  );

  const handleSelectPoint = (point: MapPoint | null) => {
    if (!point) {
      setSelectedPoint(null);
      return;
    }

    if (point.type === 'customer') {
      setSelectedCustomer(point);
    }

    setSelectedPoint(point);
  };

  const activeError = error ?? nearestStockError;

  return (
    <div className="relative h-full w-full overflow-hidden rounded-xl border border-border">
      {isLoading && points.length === 0 ? (
        <div className="absolute inset-0 z-[2000] flex items-center justify-center bg-background/80">
          <span className="text-sm text-text-muted">Loading map…</span>
        </div>
      ) : null}

      {activeError ? (
        <div className="absolute bottom-4 left-4 z-[1000] rounded-xl border border-danger/20 bg-background/95 px-3 py-2 text-sm text-danger shadow-lg">
          {activeError}
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

      {selectedPoint ? (
        <SidePanel
          selectedPoint={selectedPoint}
          selectedCustomer={selectedCustomer}
          nearestStock={nearestStock}
          isNearestStockLoading={isNearestStockLoading}
          resourceSelected={Boolean(selectedResourceId)}
          needed={needed}
          stockByWarehouseId={stockByWarehouseId}
          onWarehouseSelect={(warehouseId) => {
            const warehousePoint = warehousePointsById[warehouseId];

            if (warehousePoint) {
              setSelectedPoint(warehousePoint);
            }
          }}
          onClose={() => setSelectedPoint(null)}
        />
      ) : null}

      {hasActiveNearestStockSearch && !isNearestStockLoading && nearestStock.length === 0 ? (
        <div className="absolute bottom-4 right-4 z-[1000] rounded-xl border border-border bg-background/95 px-3 py-2 text-sm text-text-muted shadow-lg">
          No stock available.
        </div>
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
        <MarkersLayer
          points={renderablePoints}
          selectedId={selectedPoint?.id}
          needed={needed}
          onSelect={handleSelectPoint}
        />
        <MapViewportController
          defaultCenter={DEFAULT_CENTER}
          selectedPoint={selectedPoint}
          resultPoints={mapFocusPoints}
        />
      </MapContainer>
    </div>
  );
}
