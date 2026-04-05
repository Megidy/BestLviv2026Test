import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { useEffect, useMemo, useRef, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { MapContainer, TileLayer, useMap as useLeafletMap } from 'react-leaflet';
import { RotateCcw, SlidersHorizontal, X } from 'lucide-react';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { useInventory } from '@/features/inventory/hooks/useInventory';
import { useMap } from '@/features/map/hooks/useMap';
import { useNearestStock } from '@/features/map/useNearestStock';
import type { MapPoint, MapPointStatus, NearestStockResult } from '@/shared/api';
import { cn } from '@/shared/lib/cn';
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
const PANEL_BREAKPOINT_PX = 1024;

type Filter = 'all' | MapPointStatus;
type MapViewportMode = 'default' | 'selected' | 'nearest-results';
type StockMarkerTone = 'good' | 'borderline' | 'critical';

type RenderablePoint = {
  point: MapPoint;
  nearestStock?: NearestStockResult;
};

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
  neededQuantity: number,
): StockMarkerTone {
  if (result.surplus >= neededQuantity * 1.5) {
    return 'good';
  }

  if (result.surplus >= neededQuantity) {
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

function hasValidCoordinates(point: MapPoint | null | undefined) {
  return Boolean(
    point &&
      Number.isFinite(point.lat) &&
      Number.isFinite(point.lng) &&
      Math.abs(point.lat) <= 90 &&
      Math.abs(point.lng) <= 180,
  );
}

function dedupePoints(points: (MapPoint | null | undefined)[]) {
  const deduped = new Map<number, MapPoint>();

  for (const point of points) {
    if (!point || !hasValidCoordinates(point)) {
      continue;
    }

    deduped.set(point.id, point);
  }

  return Array.from(deduped.values());
}

function getVisibleMarkers(
  points: MapPoint[],
  statusFilter: Filter,
  selectedOriginPoint: MapPoint | null,
  highlightedCandidatePoints: MapPoint[],
  selectedMarkerPoint: MapPoint | null,
) {
  const filteredPoints =
    statusFilter === 'all'
      ? points.filter(hasValidCoordinates)
      : points.filter((point) => point.status === statusFilter && hasValidCoordinates(point));

  return dedupePoints([
    ...filteredPoints,
    selectedOriginPoint,
    selectedMarkerPoint,
    ...highlightedCandidatePoints,
  ]);
}

function getBoundsForMarkers(points: MapPoint[]) {
  const coordinates = points
    .filter(hasValidCoordinates)
    .map((point) => [point.lat, point.lng] as [number, number]);

  if (coordinates.length === 0) {
    return null;
  }

  return L.latLngBounds(coordinates);
}

function useIsCompactLayout(breakpointPx = PANEL_BREAKPOINT_PX) {
  const [isCompactLayout, setIsCompactLayout] = useState(() => {
    if (typeof window === 'undefined') {
      return false;
    }

    return window.innerWidth < breakpointPx;
  });

  useEffect(() => {
    if (typeof window === 'undefined') {
      return;
    }

    const mediaQuery = window.matchMedia(`(max-width: ${breakpointPx - 1}px)`);
    const handleChange = (event: MediaQueryListEvent) => {
      setIsCompactLayout(event.matches);
    };

    setIsCompactLayout(mediaQuery.matches);
    mediaQuery.addEventListener('change', handleChange);

    return () => mediaQuery.removeEventListener('change', handleChange);
  }, [breakpointPx]);

  return isCompactLayout;
}

function MarkersLayer({
  points,
  selectedId,
  neededQuantity,
  onSelect,
}: {
  points: RenderablePoint[];
  selectedId?: number | null;
  neededQuantity: number;
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
          ? getStockMarkerTone(nearestStock, neededQuantity)
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
  }, [map, neededQuantity, onSelect, points, selectedId]);

  return null;
}

function MapViewportController({
  defaultCenter,
  viewportMode,
  defaultPoints,
  selectedPoint,
  nearestResultPoints,
  isCompactLayout,
}: {
  defaultCenter: [number, number];
  viewportMode: MapViewportMode;
  defaultPoints: MapPoint[];
  selectedPoint: MapPoint | null;
  nearestResultPoints: MapPoint[];
  isCompactLayout: boolean;
}) {
  const map = useLeafletMap();

  useEffect(() => {
    const boundsPadding = {
      paddingTopLeft: [24, 24] as L.PointTuple,
      paddingBottomRight: isCompactLayout ? ([24, 220] as L.PointTuple) : ([360, 24] as L.PointTuple),
      maxZoom: 11,
      animate: true,
    };

    if (viewportMode === 'nearest-results') {
      const bounds = getBoundsForMarkers(nearestResultPoints);

      if (bounds) {
        map.fitBounds(bounds, boundsPadding);
        return;
      }
    }

    if (viewportMode === 'selected' && selectedPoint && hasValidCoordinates(selectedPoint)) {
      map.setView(
        [selectedPoint.lat, selectedPoint.lng],
        Math.max(map.getZoom(), 11),
        { animate: true },
      );
      return;
    }

    const defaultBounds = getBoundsForMarkers(defaultPoints);

    if (defaultBounds) {
      map.fitBounds(defaultBounds, {
        padding: [48, 48],
        maxZoom: 11,
        animate: true,
      });
      return;
    }

    map.setView(defaultCenter, DEFAULT_ZOOM, { animate: true });
  }, [
    defaultCenter,
    defaultPoints,
    isCompactLayout,
    map,
    nearestResultPoints,
    selectedPoint,
    viewportMode,
  ]);

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
    <div className="flex max-w-[calc(100%-2rem)] overflow-x-auto rounded-xl border border-border bg-background/90 p-1.5 shadow backdrop-blur sm:max-w-[24rem]">
      {filters.map((filter) => (
        <button
          key={filter}
          onClick={() => onChange(filter)}
          aria-pressed={active === filter}
          className={cn(
            'shrink-0 rounded-lg px-3 py-1 text-xs font-medium capitalize transition-colors',
            active === filter
              ? 'bg-primary text-background'
              : 'text-text-muted hover:bg-white/5 hover:text-text',
          )}
        >
          {filter}
        </button>
      ))}
    </div>
  );
}

type SidePanelProps = {
  selectedPoint: MapPoint;
  selectedOriginPoint: MapPoint | null;
  nearestStockResults: NearestStockResult[];
  isNearestStockLoading: boolean;
  nearestStockError: string | null;
  resourceSelected: boolean;
  neededQuantity: number;
  stockByWarehouseId: Record<number, NearestStockResult>;
  onWarehouseSelect: (warehouseId: number) => void;
  onClose: () => void;
  isCompactLayout: boolean;
};

function SidePanel({
  selectedPoint,
  selectedOriginPoint,
  nearestStockResults,
  isNearestStockLoading,
  nearestStockError,
  resourceSelected,
  neededQuantity,
  stockByWarehouseId,
  onWarehouseSelect,
  onClose,
  isCompactLayout,
}: SidePanelProps) {
  const selectedWarehouseStock =
    selectedPoint.type === 'warehouse'
      ? stockByWarehouseId[selectedPoint.id]
      : undefined;

  return (
    <div
      className={cn(
        'absolute z-[1000] overflow-hidden border border-border bg-background/95 shadow-xl backdrop-blur',
        isCompactLayout
          ? 'bottom-0 left-0 right-0 max-h-[70vh] rounded-t-2xl'
          : 'bottom-4 right-4 top-4 w-[22rem] rounded-2xl',
      )}
    >
      <div className="flex h-full max-h-[inherit] flex-col">
        <div className="sticky top-0 z-10 border-b border-border bg-background/95 px-4 py-4">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0">
              <p className="truncate font-semibold text-text">{selectedPoint.name}</p>
              <p className="text-xs capitalize text-text-muted">{selectedPoint.type}</p>
            </div>
            <button
              onClick={onClose}
              className="rounded-lg p-1 text-text-muted transition-colors hover:bg-white/5 hover:text-text"
              aria-label="Close"
            >
              <X size={16} />
            </button>
          </div>

          <div className="mt-3 flex flex-wrap items-center gap-2">
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
        </div>

        <div className="min-h-0 flex-1 overflow-y-auto px-4 py-4">
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

          {selectedOriginPoint && selectedPoint.type === 'customer' ? (
            <div className="mt-4 border-t border-border pt-4">
              <p className="text-xs uppercase tracking-[0.18em] text-text-muted">
                Nearest stock
              </p>
              {!resourceSelected ? (
                <p className="mt-2 text-sm text-text-muted">
                  Select a resource to rank nearby warehouses.
                </p>
              ) : nearestStockError ? (
                <p className="mt-2 text-sm text-danger">{nearestStockError}</p>
              ) : isNearestStockLoading ? (
                <p className="mt-2 text-sm text-text-muted">Loading nearest stock…</p>
              ) : nearestStockResults.length === 0 ? (
                <p className="mt-2 text-sm text-text-muted">
                  No stock available for {formatNumber(neededQuantity)} units with safety
                  stock applied.
                </p>
              ) : (
                <div className="mt-3 space-y-2">
                  {nearestStockResults.map((entry) => (
                    <button
                      type="button"
                      key={entry.warehouse_id}
                      onClick={() => onWarehouseSelect(entry.warehouse_id)}
                      className="block w-full rounded-xl border border-border bg-surface/50 p-3 text-left transition-colors hover:border-primary/30 hover:bg-surface"
                    >
                      <p className="text-sm font-medium">{entry.warehouse_name}</p>
                      <p className="mt-1 text-xs text-text-muted">
                        {formatNumber(entry.surplus)} available
                      </p>
                      <p className="text-xs text-text-muted">
                        {formatNumber(entry.distance_km)} km ·{' '}
                        {formatNumber(entry.estimated_arrival_hours)}h ETA
                      </p>
                    </button>
                  ))}
                </div>
              )}
            </div>
          ) : null}

          {selectedOriginPoint && selectedPoint.type === 'warehouse' ? (
            <p className="mt-4 border-t border-border pt-4 text-xs text-text-muted">
              Serving {selectedOriginPoint.name} for {formatNumber(neededQuantity)} units.
            </p>
          ) : null}
        </div>
      </div>
    </div>
  );
}

export function MapView() {
  const [searchParams] = useSearchParams();
  const focusId = searchParams.get('focusId') ? Number(searchParams.get('focusId')) : null;
  const focusType = searchParams.get('focusType') ?? null;
  const isCompactLayout = useIsCompactLayout();
  const { user } = useAuth();

  const [statusFilter, setStatusFilter] = useState<Filter>('all');
  const [selectedOriginPointId, setSelectedOriginPointId] = useState<number | null>(null);
  const [selectedMarkerId, setSelectedMarkerId] = useState<number | null>(null);
  const [selectedResourceId, setSelectedResourceId] = useState<number | undefined>();
  const [neededQuantity, setNeededQuantity] = useState(100);
  const [isDetailsPanelOpen, setIsDetailsPanelOpen] = useState(false);
  const [mapViewportMode, setMapViewportMode] = useState<MapViewportMode>('default');
  const [filtersOpen, setFiltersOpen] = useState(false);

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

  const pointsById = useMemo(
    () => Object.fromEntries(points.map((point) => [point.id, point])),
    [points],
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

  const selectedOriginPoint = selectedOriginPointId
    ? pointsById[selectedOriginPointId] ?? null
    : null;
  const selectedMarkerPoint = selectedMarkerId ? pointsById[selectedMarkerId] ?? null : null;

  const {
    data: nearestStockResults,
    isLoading: isNearestStockLoading,
    error: nearestStockError,
    clear: clearNearestStockResults,
  } = useNearestStock({
    resourceId: selectedResourceId,
    customerId: selectedOriginPoint?.id,
    needed: Number(neededQuantity),
    enabled: Boolean(selectedOriginPoint?.id && selectedResourceId && Number(neededQuantity) > 0),
  });

  useEffect(() => {
    if (!selectedResourceId && resourceOptions.length > 0) {
      setSelectedResourceId(resourceOptions[0].id);
    }
  }, [resourceOptions, selectedResourceId]);

  useEffect(() => {
    if (selectedOriginPointId && !selectedOriginPoint) {
      setSelectedOriginPointId(null);
    }

    if (selectedMarkerId && !selectedMarkerPoint) {
      setSelectedMarkerId(null);
      setIsDetailsPanelOpen(false);
    }
  }, [
    selectedMarkerId,
    selectedMarkerPoint,
    selectedOriginPoint,
    selectedOriginPointId,
  ]);

  useEffect(() => {
    if (!focusId || points.length === 0) {
      return;
    }

    const target = points.find(
      (point) => point.id === focusId && (focusType ? point.type === focusType : true),
    );

    if (!target) {
      return;
    }

    setSelectedMarkerId(target.id);
    setIsDetailsPanelOpen(true);

    if (target.type === 'customer') {
      setSelectedOriginPointId(target.id);
      setMapViewportMode('selected');
      return;
    }

    setMapViewportMode('selected');
  }, [focusId, focusType, points]);

  useEffect(() => {
    if (!isDetailsPanelOpen || !selectedMarkerPoint) {
      setMapViewportMode('default');
      return;
    }

    if (selectedOriginPoint && nearestStockResults.length > 0) {
      setMapViewportMode('nearest-results');
      return;
    }

    setMapViewportMode('selected');
  }, [
    isDetailsPanelOpen,
    nearestStockResults.length,
    selectedMarkerPoint,
    selectedOriginPoint,
  ]);

  const stockByWarehouseId = useMemo(
    () =>
      Object.fromEntries(
        nearestStockResults.map((entry) => [entry.warehouse_id, entry]),
      ),
    [nearestStockResults],
  );

  const highlightedCandidatePoints = useMemo(
    () =>
      nearestStockResults
        .map((entry) => warehousePointsById[entry.warehouse_id])
        .filter((point): point is MapPoint => Boolean(point) && hasValidCoordinates(point)),
    [nearestStockResults, warehousePointsById],
  );

  const visibleMarkers = useMemo(
    () =>
      getVisibleMarkers(
        points,
        statusFilter,
        selectedOriginPoint,
        highlightedCandidatePoints,
        selectedMarkerPoint,
      ),
    [
      highlightedCandidatePoints,
      points,
      selectedMarkerPoint,
      selectedOriginPoint,
      statusFilter,
    ],
  );

  const renderablePoints = useMemo(
    () =>
      visibleMarkers.map((point) => ({
        point,
        nearestStock: point.type === 'warehouse' ? stockByWarehouseId[point.id] : undefined,
      })),
    [stockByWarehouseId, visibleMarkers],
  );

  const nearestViewportPoints = useMemo(
    () => dedupePoints([selectedOriginPoint, ...highlightedCandidatePoints]),
    [highlightedCandidatePoints, selectedOriginPoint],
  );

  const helperMessage =
    'Спочатку виберіть точку доставки / клієнта на мапі';

  const resetMapSelection = () => {
    setSelectedOriginPointId(null);
    setSelectedMarkerId(null);
    setIsDetailsPanelOpen(false);
    setMapViewportMode('default');
    clearNearestStockResults();
  };

  const handleSelectPoint = (point: MapPoint | null) => {
    if (!point) {
      resetMapSelection();
      return;
    }

    setSelectedMarkerId(point.id);
    setIsDetailsPanelOpen(true);

    if (point.type === 'customer') {
      setSelectedOriginPointId(point.id);
      setMapViewportMode('selected');
      return;
    }

    setMapViewportMode('selected');
  };

  const activeError = error ?? nearestStockError;

  return (
    <div className="relative h-full w-full overflow-hidden rounded-xl border border-border">
      {isLoading && points.length === 0 ? (
        <div className="absolute inset-0 z-[2000] flex items-center justify-center bg-background/80">
          <span className="text-sm text-text-muted">Loading map…</span>
        </div>
      ) : null}

      {activeError && !selectedOriginPoint ? (
        <div className="absolute bottom-4 left-4 z-[1000] rounded-xl border border-danger/20 bg-background/95 px-3 py-2 text-sm text-danger shadow-lg">
          {activeError}
        </div>
      ) : null}

      <div className="absolute left-4 top-4 z-[1000] sm:hidden">
        <button
          type="button"
          onClick={() => setFiltersOpen((prev) => !prev)}
          aria-label="Open map filters"
          aria-expanded={filtersOpen}
          className={cn(
            'flex h-9 w-9 items-center justify-center rounded-xl border border-border shadow backdrop-blur transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/60',
            filtersOpen
              ? 'bg-primary text-background'
              : 'bg-background/90 text-text-muted hover:text-text',
          )}
        >
          <SlidersHorizontal size={16} />
        </button>

        {filtersOpen ? (
          <div className="absolute left-0 top-11 w-72 rounded-xl border border-border bg-background/95 p-3 shadow-xl backdrop-blur">
            <div className="mb-3 flex items-center justify-between">
              <p className="text-xs font-medium uppercase tracking-[0.15em] text-text-muted">
                Filters
              </p>
              <button
                type="button"
                onClick={() => setFiltersOpen(false)}
                aria-label="Close filters"
                className="text-text-muted transition-colors hover:text-text"
              >
                <X size={14} />
              </button>
            </div>

            <div className="mb-3 flex flex-wrap gap-1.5">
              {(['all', 'critical', 'elevated', 'predictive', 'normal'] as Filter[]).map(
                (filterOption) => (
                  <button
                    key={filterOption}
                    onClick={() => setStatusFilter(filterOption)}
                    aria-pressed={statusFilter === filterOption}
                    className={cn(
                      'rounded-lg px-3 py-1 text-xs font-medium capitalize transition-colors',
                      statusFilter === filterOption
                        ? 'bg-primary text-background'
                        : 'text-text-muted hover:bg-white/5 hover:text-text',
                    )}
                  >
                    {filterOption}
                  </button>
                ),
              )}
            </div>

            <div className="space-y-2 border-t border-border pt-3">
              <div className="space-y-1">
                <label className="text-xs text-text-muted">Resource</label>
                <select
                  aria-label="Select resource"
                  className="h-9 w-full appearance-none rounded-xl border border-border bg-surface/80 pl-3 pr-7 text-sm text-text outline-none focus:border-primary/60 focus:ring-2 focus:ring-primary/20"
                  style={{
                    backgroundImage:
                      'url("data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'16\' height=\'16\' viewBox=\'0 0 24 24\' fill=\'none\' stroke=\'%23D1C1A7\' stroke-width=\'2\' stroke-linecap=\'round\' stroke-linejoin=\'round\'%3E%3Cpolyline points=\'6 9 12 15 18 9\'%3E%3C/polyline%3E%3C/svg%3E")',
                    backgroundRepeat: 'no-repeat',
                    backgroundPosition: 'right 8px center',
                  }}
                  value={selectedResourceId ?? ''}
                  onChange={(event) =>
                    setSelectedResourceId(
                      event.target.value === '' ? undefined : Number(event.target.value),
                    )
                  }
                >
                  {resourceOptions.map((option) => (
                    <option key={option.id} value={option.id}>
                      {option.name}
                    </option>
                  ))}
                </select>
              </div>

              <div className="space-y-1">
                <label className="text-xs text-text-muted">Quantity needed</label>
                <input
                  aria-label="Quantity needed"
                  className="h-9 w-full rounded-xl border border-border bg-surface/80 px-3 text-sm text-text outline-none focus:border-primary/60 focus:ring-2 focus:ring-primary/20"
                  min={1}
                  max={1000000}
                  step={1}
                  type="number"
                  value={neededQuantity}
                  onChange={(event) =>
                    setNeededQuantity(
                      Math.min(1000000, Math.max(1, Number(event.target.value) || 1)),
                    )
                  }
                />
              </div>

              {!selectedOriginPoint ? (
                <p className="rounded-xl border border-border bg-surface/50 px-3 py-2 text-xs text-text-muted">
                  {helperMessage}
                </p>
              ) : null}

              {(selectedOriginPoint || selectedMarkerPoint) && (
                <button
                  type="button"
                  onClick={resetMapSelection}
                  className="flex w-full items-center justify-center gap-2 rounded-xl border border-border bg-surface/50 px-3 py-2 text-sm text-text transition-colors hover:bg-surface"
                >
                  <RotateCcw size={14} />
                  Reset view
                </button>
              )}
            </div>
          </div>
        ) : null}
      </div>

      <div className="absolute left-4 top-4 z-[1000] hidden flex-col gap-2 sm:flex">
        <FilterBar active={statusFilter} onChange={setStatusFilter} />

        <div className="flex max-w-[28rem] flex-wrap gap-2 rounded-xl border border-border bg-background/90 p-3 shadow backdrop-blur">
          <select
            aria-label="Select resource"
            className="h-10 min-w-[88px] appearance-none rounded-xl border border-border bg-surface/80 pl-3 pr-7 text-sm text-text outline-none focus:border-primary/60 focus:ring-2 focus:ring-primary/20"
            style={{
              backgroundImage:
                'url("data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'16\' height=\'16\' viewBox=\'0 0 24 24\' fill=\'none\' stroke=\'%23D1C1A7\' stroke-width=\'2\' stroke-linecap=\'round\' stroke-linejoin=\'round\'%3E%3Cpolyline points=\'6 9 12 15 18 9\'%3E%3C/polyline%3E%3C/svg%3E")',
              backgroundRepeat: 'no-repeat',
              backgroundPosition: 'right 8px center',
            }}
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
            aria-label="Quantity needed"
            className="h-10 w-28 rounded-xl border border-border bg-surface/80 px-3 text-sm text-text outline-none focus:border-primary/60 focus:ring-2 focus:ring-primary/20"
            min={1}
            max={1000000}
            step={1}
            type="number"
            value={neededQuantity}
            onChange={(event) =>
              setNeededQuantity(
                Math.min(1000000, Math.max(1, Number(event.target.value) || 1)),
              )
            }
          />

          {(selectedOriginPoint || selectedMarkerPoint) && (
            <button
              type="button"
              onClick={resetMapSelection}
              className="flex h-10 items-center gap-2 rounded-xl border border-border bg-surface/50 px-3 text-sm text-text transition-colors hover:bg-surface"
            >
              <RotateCcw size={14} />
              Reset view
            </button>
          )}

          {!selectedOriginPoint ? (
            <p className="basis-full text-xs text-text-muted">{helperMessage}</p>
          ) : null}
        </div>
      </div>

      {isDetailsPanelOpen && selectedMarkerPoint ? (
        <SidePanel
          selectedPoint={selectedMarkerPoint}
          selectedOriginPoint={selectedOriginPoint}
          nearestStockResults={nearestStockResults}
          isNearestStockLoading={isNearestStockLoading}
          nearestStockError={nearestStockError}
          resourceSelected={Boolean(selectedResourceId)}
          neededQuantity={neededQuantity}
          stockByWarehouseId={stockByWarehouseId}
          onWarehouseSelect={(warehouseId) => {
            const warehousePoint = warehousePointsById[warehouseId];

            if (warehousePoint) {
              setSelectedMarkerId(warehousePoint.id);
              setIsDetailsPanelOpen(true);
              setMapViewportMode('nearest-results');
            }
          }}
          onClose={resetMapSelection}
          isCompactLayout={isCompactLayout}
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
        <MarkersLayer
          points={renderablePoints}
          selectedId={selectedMarkerId}
          neededQuantity={neededQuantity}
          onSelect={handleSelectPoint}
        />
        <MapViewportController
          defaultCenter={DEFAULT_CENTER}
          viewportMode={mapViewportMode}
          defaultPoints={visibleMarkers}
          selectedPoint={selectedMarkerPoint}
          nearestResultPoints={nearestViewportPoints}
          isCompactLayout={isCompactLayout}
        />
      </MapContainer>
    </div>
  );
}
