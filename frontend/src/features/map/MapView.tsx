import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { useEffect, useMemo, useRef, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { MapContainer, TileLayer, useMap as useLeafletMap } from 'react-leaflet';
import { Minus, Plus, RotateCcw, X, Warehouse, MapPin, AlertTriangle } from 'lucide-react';

import { useNavigate } from 'react-router-dom';

import { useMap } from '@/features/map/hooks/useMap';
import { useNearestStock } from '@/features/map/useNearestStock';
import type { MapPoint, MapPointStatus, NearestStockResult } from '@/shared/api';
import { cn } from '@/shared/lib/cn';
import { formatNumber, mapStatusTone } from '@/shared/lib/formatters';
import { Badge } from '@/shared/ui/Badge';

// ─── Constants ────────────────────────────────────────────────────────────────

const STATUS_COLOR: Record<MapPointStatus, string> = {
  normal: '#4ade80',
  elevated: '#fbbf24',
  critical: '#f87171',
  predictive: '#a78bfa',
};

const STATUS_LABEL: Record<MapPointStatus, string> = {
  normal: 'Normal',
  elevated: 'Elevated',
  critical: 'Critical',
  predictive: 'Predictive',
};

const DEFAULT_CENTER: [number, number] = [49.0, 31.5]; // Centre of Ukraine
const DEFAULT_ZOOM = 6;

// ─── Types ────────────────────────────────────────────────────────────────────

export type StatusFilter = 'all' | MapPointStatus;
export type TypeFilter = 'all' | 'customer' | 'warehouse';
type StockTone = 'good' | 'borderline' | 'critical';

type RenderablePoint = { point: MapPoint; nearestStock?: NearestStockResult };

export interface MapViewProps {
  statusFilter: StatusFilter;
  typeFilter: TypeFilter;
  selectedResourceId: number | undefined;
  neededQty: number;
  /** Compact mode: clicking a marker navigates to the full map page instead of opening the side panel. */
  compact?: boolean;
}

// ─── Marker factory ───────────────────────────────────────────────────────────

function makeIcon(
  status: MapPointStatus,
  type: 'warehouse' | 'customer',
  opts: { highlight?: string; selected?: boolean } = {},
) {
  const color = opts.highlight ?? STATUS_COLOR[status];
  const isWarehouse = type === 'warehouse';
  const size = isWarehouse ? 20 : 14;
  const selectedSize = isWarehouse ? 24 : 18;
  const s = opts.selected ? selectedSize : size;

  const pulseCls =
    status === 'critical' || opts.highlight === STATUS_COLOR.critical
      ? 'map-marker--pulse-fast'
      : status === 'elevated'
        ? 'map-marker--pulse-slow'
        : '';

  const ring = opts.selected
    ? `box-shadow:0 0 0 3px ${color}55,0 0 14px ${color}88;`
    : `box-shadow:0 0 6px ${color}66;`;

  const shape = isWarehouse
    ? `border-radius:4px;transform:rotate(45deg);`
    : `border-radius:50%;`;

  const html = `<span class="map-marker ${pulseCls}" style="
    background:${color};
    width:${s}px;height:${s}px;
    display:block;
    border:2px solid rgba(255,255,255,0.75);
    ${shape}
    ${ring}
    transition:box-shadow .15s;
  "></span>`;

  return L.divIcon({ html, className: '', iconSize: [s, s], iconAnchor: [s / 2, s / 2] });
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function hasValidCoords(p: MapPoint | null | undefined) {
  return Boolean(
    p && Number.isFinite(p.lat) && Number.isFinite(p.lng) &&
    Math.abs(p.lat) <= 90 && Math.abs(p.lng) <= 180,
  );
}

function dedupePoints(pts: (MapPoint | null | undefined)[]): MapPoint[] {
  const map = new Map<number, MapPoint>();
  for (const p of pts) if (p && hasValidCoords(p)) map.set(p.id, p);
  return Array.from(map.values());
}

function getStockTone(r: NearestStockResult, needed: number): StockTone {
  if (r.surplus >= needed * 1.5) return 'good';
  if (r.surplus >= needed) return 'borderline';
  return 'critical';
}

function stockColor(tone: StockTone) {
  return tone === 'good' ? '#4ade80' : tone === 'borderline' ? '#fbbf24' : '#f87171';
}

function getVisibleMarkers(
  points: MapPoint[],
  status: StatusFilter,
  type: TypeFilter,
  origin: MapPoint | null,
  candidates: MapPoint[],
  selected: MapPoint | null,
): MapPoint[] {
  const filtered = points
    .filter(hasValidCoords)
    .filter(p => status === 'all' || p.status === status)
    .filter(p => type === 'all' || p.type === type);
  return dedupePoints([...filtered, origin, selected, ...candidates]);
}

function fitBoundsForPoints(map: L.Map, pts: MapPoint[], padding = [48, 48] as [number, number]) {
  const coords = pts.filter(hasValidCoords).map(p => [p.lat, p.lng] as [number, number]);
  if (coords.length === 0) return;
  map.fitBounds(L.latLngBounds(coords), { padding, maxZoom: 11, animate: true });
}

// ─── Leaflet sub-components ───────────────────────────────────────────────────

function MarkersLayer({
  points, selectedId, neededQty, onSelect,
}: {
  points: RenderablePoint[];
  selectedId?: number | null;
  neededQty: number;
  onSelect: (p: MapPoint | null) => void;
}) {
  const map = useLeafletMap();
  const layerRef = useRef<L.LayerGroup | null>(null);

  useEffect(() => {
    if (layerRef.current) layerRef.current.clearLayers();
    else layerRef.current = L.layerGroup().addTo(map);

    for (const { point, nearestStock } of points) {
      const tone = nearestStock && point.type === 'warehouse'
        ? getStockTone(nearestStock, neededQty) : null;
      const highlight = tone ? stockColor(tone) : undefined;
      const selected = point.id === selectedId;

      const marker = L.marker([point.lat, point.lng], {
        icon: makeIcon(point.status, point.type, { highlight, selected }),
        zIndexOffset: selected ? 1000 : 0,
      });

      // Tooltip with name
      marker.bindTooltip(point.name, {
        permanent: false,
        direction: 'top',
        offset: [0, -8],
        className: 'map-tooltip',
      });

      if (nearestStock && point.type === 'warehouse') {
        marker.bindPopup(`
          <div style="min-width:160px;font-size:13px;line-height:1.5">
            <strong>${nearestStock.warehouse_name}</strong><br/>
            Available: ${formatNumber(nearestStock.surplus)}<br/>
            ${formatNumber(nearestStock.distance_km)} km · ${formatNumber(nearestStock.estimated_arrival_hours)}h ETA
          </div>
        `);
      }

      marker.on('click', () => onSelect(point));
      layerRef.current?.addLayer(marker);
    }

    return () => { layerRef.current?.clearLayers(); };
  }, [map, neededQty, onSelect, points, selectedId]);

  return null;
}

function ViewportController({
  initialPoints, selectedPoint, candidatePoints, mode,
}: {
  initialPoints: MapPoint[];
  selectedPoint: MapPoint | null;
  candidatePoints: MapPoint[];
  mode: 'default' | 'selected' | 'candidates';
}) {
  const map = useLeafletMap();
  const didInitialFit = useRef(false);

  // One-time initial fit when points first load
  useEffect(() => {
    if (didInitialFit.current || initialPoints.length === 0) return;
    fitBoundsForPoints(map, initialPoints, [48, 48]);
    didInitialFit.current = true;
  }, [map, initialPoints]);

  // Zoom to selected point only when user explicitly picks one
  useEffect(() => {
    if (mode !== 'selected' || !selectedPoint || !hasValidCoords(selectedPoint)) return;
    map.setView([selectedPoint.lat, selectedPoint.lng], Math.max(map.getZoom(), 10), { animate: true });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [map, selectedPoint?.id]); // dep on id, not object reference — avoids re-fires

  // Fit to candidates when nearest stock loads
  useEffect(() => {
    if (mode !== 'candidates' || candidatePoints.length === 0) return;
    const pts = dedupePoints([selectedPoint, ...candidatePoints]);
    fitBoundsForPoints(map, pts, [60, 60]);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [map, candidatePoints.length]); // dep on length — fires once when results arrive

  return null;
}

function ZoomControl() {
  const map = useLeafletMap();
  return (
    <div className="absolute bottom-6 right-4 z-[1000] flex flex-col gap-1">
      {[
        { icon: Plus, action: () => map.zoomIn(), label: 'Zoom in' },
        { icon: Minus, action: () => map.zoomOut(), label: 'Zoom out' },
      ].map(({ icon: Icon, action, label }) => (
        <button
          key={label}
          type="button"
          aria-label={label}
          onClick={action}
          className="flex h-9 w-9 items-center justify-center rounded-xl border border-border bg-background/90 text-text-muted shadow backdrop-blur transition-colors hover:bg-surface hover:text-text"
        >
          <Icon size={16} />
        </button>
      ))}
    </div>
  );
}

// ─── Controls panel (exported for use in MapPage) ─────────────────────────────

const BTN = (active: boolean) =>
  cn('shrink-0 rounded-md px-2 py-0.5 text-xs font-medium transition-colors',
    active ? 'bg-primary text-background' : 'text-text-muted hover:bg-white/5 hover:text-text');

export function ControlPanel({
  statusFilter, setStatusFilter,
  typeFilter, setTypeFilter,
  resourceOptions, selectedResourceId, setSelectedResourceId,
  neededQty, setNeededQty,
}: {
  statusFilter: StatusFilter;
  setStatusFilter: (s: StatusFilter) => void;
  typeFilter: TypeFilter;
  setTypeFilter: (t: TypeFilter) => void;
  resourceOptions: { id: number; name: string }[];
  selectedResourceId: number | undefined;
  setSelectedResourceId: (id: number | undefined) => void;
  neededQty: number;
  setNeededQty: (n: number) => void;
}) {
  const statuses: StatusFilter[] = ['all', 'critical', 'elevated', 'predictive', 'normal'];
  const types: { value: TypeFilter; label: string }[] = [
    { value: 'customer', label: 'Customers' },
    { value: 'warehouse', label: 'Warehouses' },
    { value: 'all', label: 'All' },
  ];

  return (
    <div className="flex flex-wrap items-center gap-2 rounded-xl border border-border bg-surface/60 px-3 py-2">
      {/* Type segment */}
      <div className="flex shrink-0 rounded-lg border border-border/60 bg-background/60 p-0.5">
        {types.map(({ value, label }) => (
          <button key={value} onClick={() => setTypeFilter(value)} aria-pressed={typeFilter === value}
            className={BTN(typeFilter === value)}>
            {label}
          </button>
        ))}
      </div>

      <div className="h-4 w-px shrink-0 bg-border" />

      {/* Status pills */}
      <div className="flex flex-wrap items-center gap-0.5">
        {statuses.map(s => (
          <button key={s} onClick={() => setStatusFilter(s)} aria-pressed={statusFilter === s}
            className={cn(BTN(statusFilter === s), 'flex items-center gap-1')}>
            {s !== 'all' && (
              <span className="h-1.5 w-1.5 shrink-0 rounded-full"
                style={{ background: STATUS_COLOR[s as MapPointStatus] }} />
            )}
            <span className="capitalize">{s}</span>
          </button>
        ))}
      </div>

      <div className="h-4 w-px shrink-0 bg-border" />

      {/* Resource + qty */}
      <div className="flex items-center gap-1.5">
        <div className="relative">
          <select
            aria-label="Select resource"
            className="h-7 appearance-none rounded-lg border border-border bg-background/60 pl-2 pr-5 text-xs text-text outline-none focus:border-primary/60"
            value={selectedResourceId ?? ''}
            onChange={e => setSelectedResourceId(e.target.value === '' ? undefined : Number(e.target.value))}
          >
            {resourceOptions.map(o => <option key={o.id} value={o.id}>{o.name}</option>)}
          </select>
          <span className="pointer-events-none absolute right-1.5 top-1/2 -translate-y-1/2 text-text-muted">
            <svg width="9" height="9" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="6 9 12 15 18 9" /></svg>
          </span>
        </div>
        <input
          aria-label="Quantity"
          type="number" min={1} max={1000000}
          className="h-7 w-16 rounded-lg border border-border bg-background/60 px-2 text-xs text-text outline-none focus:border-primary/60"
          value={neededQty}
          onChange={e => setNeededQty(Math.min(1000000, Math.max(1, Number(e.target.value) || 1)))}
        />
      </div>
    </div>
  );
}

// ─── Side panel ───────────────────────────────────────────────────────────────

function SidePanel({
  point, originPoint, nearestStock, isLoadingStock, stockError,
  resourceSelected, neededQty, stockById,
  onWarehouseSelect, onClose,
}: {
  point: MapPoint;
  originPoint: MapPoint | null;
  nearestStock: NearestStockResult[];
  isLoadingStock: boolean;
  stockError: string | null;
  resourceSelected: boolean;
  neededQty: number;
  stockById: Record<number, NearestStockResult>;
  onWarehouseSelect: (id: number) => void;
  onClose: () => void;
}) {
  const warehouseStock = point.type === 'warehouse' ? stockById[point.id] : undefined;

  return (
    <div className="absolute bottom-0 left-0 right-0 z-[1000] max-h-[65vh] overflow-hidden rounded-t-2xl border-t border-border bg-background/98 shadow-2xl backdrop-blur lg:bottom-4 lg:left-auto lg:right-4 lg:top-4 lg:w-80 lg:max-h-none lg:rounded-2xl lg:border">
      <div className="flex h-full max-h-[inherit] flex-col">
        {/* Header */}
        <div className="flex items-start justify-between gap-3 border-b border-border px-4 py-4">
          <div className="min-w-0">
            <div className="flex items-center gap-2">
              {point.type === 'warehouse'
                ? <Warehouse size={14} className="shrink-0 text-text-muted" />
                : <MapPin size={14} className="shrink-0 text-text-muted" />}
              <p className="truncate font-semibold text-text">{point.name}</p>
            </div>
            <div className="mt-2 flex flex-wrap items-center gap-2">
              <Badge tone={mapStatusTone(point.status)} className="capitalize">
                {STATUS_LABEL[point.status]}
              </Badge>
              {point.alert_count > 0 && (
                <span className="flex items-center gap-1 text-xs text-warning">
                  <AlertTriangle size={11} />
                  {point.alert_count} alert{point.alert_count !== 1 ? 's' : ''}
                </span>
              )}
            </div>
          </div>
          <button
            onClick={onClose}
            aria-label="Close"
            className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg text-text-muted transition-colors hover:bg-white/5 hover:text-text"
          >
            <X size={15} />
          </button>
        </div>

        {/* Body */}
        <div className="min-h-0 flex-1 overflow-y-auto space-y-4 px-4 py-4">
          {/* Coordinates */}
          <div className="grid grid-cols-2 gap-2">
            {[['Lat', point.lat.toFixed(4)], ['Lng', point.lng.toFixed(4)]].map(([label, val]) => (
              <div key={label} className="rounded-lg bg-surface/60 px-3 py-2">
                <p className="text-xs text-text-muted">{label}</p>
                <p className="mt-0.5 text-sm font-medium text-text">{val}</p>
              </div>
            ))}
          </div>

          {/* Customer: nearest stock */}
          {point.type === 'customer' && originPoint && (
            <div>
              <p className="mb-2 text-xs font-medium uppercase tracking-wider text-text-muted">
                Nearest stock
              </p>
              {!resourceSelected ? (
                <p className="text-sm text-text-muted">Select a resource above to find nearby stock.</p>
              ) : stockError ? (
                <p className="text-sm text-danger">{stockError}</p>
              ) : isLoadingStock ? (
                <p className="text-sm text-text-muted">Searching warehouses…</p>
              ) : nearestStock.length === 0 ? (
                <p className="text-sm text-text-muted">No warehouse has {formatNumber(neededQty)} units available.</p>
              ) : (
                <div className="space-y-2">
                  {nearestStock.map((entry) => {
                    const tone = getStockTone(entry, neededQty);
                    return (
                      <button
                        key={entry.warehouse_id}
                        type="button"
                        onClick={() => onWarehouseSelect(entry.warehouse_id)}
                        className="group block w-full rounded-xl border border-border bg-surface/40 p-3 text-left transition-all hover:border-primary/40 hover:bg-surface"
                      >
                        <div className="flex items-center justify-between gap-2">
                          <p className="text-sm font-medium text-text">{entry.warehouse_name}</p>
                          <span
                            className="h-2 w-2 shrink-0 rounded-full"
                            style={{ background: stockColor(tone) }}
                          />
                        </div>
                        <div className="mt-1.5 flex gap-3 text-xs text-text-muted">
                          <span>{formatNumber(entry.surplus)} avail.</span>
                          <span>{formatNumber(entry.distance_km)} km</span>
                          <span>{formatNumber(entry.estimated_arrival_hours)}h ETA</span>
                        </div>
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          )}

          {/* Warehouse: stock insight */}
          {warehouseStock && (
            <div>
              <p className="mb-2 text-xs font-medium uppercase tracking-wider text-text-muted">
                Stock insight
              </p>
              <div className="rounded-xl border border-border bg-surface/40 p-3 space-y-1.5 text-sm">
                <div className="flex justify-between">
                  <span className="text-text-muted">Available</span>
                  <span className="font-medium text-text">{formatNumber(warehouseStock.surplus)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-text-muted">Distance</span>
                  <span className="text-text">{formatNumber(warehouseStock.distance_km)} km</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-text-muted">ETA</span>
                  <span className="text-text">{formatNumber(warehouseStock.estimated_arrival_hours)} h</span>
                </div>
              </div>
            </div>
          )}

          {/* Serving note */}
          {originPoint && point.type === 'warehouse' && (
            <p className="text-xs text-text-muted">
              Serving <span className="text-text">{originPoint.name}</span> · {formatNumber(neededQty)} units needed
            </p>
          )}
        </div>

        {/* Footer action */}
        {point.type === 'customer' && (
          <div className="border-t border-border px-4 py-3">
            <Link
              to={`/delivery?destination=${point.id}`}
              className="flex w-full items-center justify-center gap-2 rounded-xl bg-primary px-4 py-2.5 text-sm font-medium text-background transition-opacity hover:opacity-90"
            >
              Create delivery request
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Main component ───────────────────────────────────────────────────────────

export function MapView({ statusFilter, typeFilter, selectedResourceId, neededQty, compact = false }: MapViewProps) {
  const [searchParams] = useSearchParams();
  const focusId = searchParams.get('focusId') ? Number(searchParams.get('focusId')) : null;
  const focusType = searchParams.get('focusType') ?? null;
  const navigate = useNavigate();

  const [selectedOriginId, setSelectedOriginId] = useState<number | null>(null);
  const [selectedMarkerId, setSelectedMarkerId] = useState<number | null>(null);
  const [panelOpen, setPanelOpen] = useState(false);
  const [viewportMode, setViewportMode] = useState<'default' | 'selected' | 'candidates'>('default');

  const { points, isLoading } = useMap();

  const pointsById = useMemo(() => Object.fromEntries(points.map(p => [p.id, p])), [points]);
  const warehouseById = useMemo(
    () => Object.fromEntries(points.filter(p => p.type === 'warehouse').map(p => [p.id, p])),
    [points],
  );

  const selectedOrigin = selectedOriginId ? pointsById[selectedOriginId] ?? null : null;
  const selectedMarker = selectedMarkerId ? pointsById[selectedMarkerId] ?? null : null;

  const { data: nearestStock, isLoading: loadingStock, error: stockError, clear: clearStock } = useNearestStock({
    resourceId: selectedResourceId,
    customerId: selectedOrigin?.id,
    needed: neededQty,
    enabled: Boolean(selectedOrigin?.id && selectedResourceId && neededQty > 0),
  });

  // Clean up stale selection
  useEffect(() => {
    if (selectedOriginId && !selectedOrigin) setSelectedOriginId(null);
    if (selectedMarkerId && !selectedMarker) { setSelectedMarkerId(null); setPanelOpen(false); }
  }, [selectedMarkerId, selectedMarker, selectedOrigin, selectedOriginId]);

  // Handle ?focusId=
  useEffect(() => {
    if (!focusId || points.length === 0) return;
    const target = points.find(p => p.id === focusId && (focusType ? p.type === focusType : true));
    if (!target) return;
    setSelectedMarkerId(target.id);
    setPanelOpen(true);
    if (target.type === 'customer') setSelectedOriginId(target.id);
    setViewportMode('selected');
  }, [focusId, focusType, points]);

  // Viewport mode
  useEffect(() => {
    if (!panelOpen || !selectedMarker) { setViewportMode('default'); return; }
    if (selectedOrigin && nearestStock.length > 0) { setViewportMode('candidates'); return; }
    setViewportMode('selected');
  }, [panelOpen, nearestStock.length, selectedMarker, selectedOrigin]);

  const stockById = useMemo(
    () => Object.fromEntries(nearestStock.map(e => [e.warehouse_id, e])),
    [nearestStock],
  );

  const candidatePoints = useMemo(
    () => nearestStock.map(e => warehouseById[e.warehouse_id]).filter((p): p is MapPoint => Boolean(p) && hasValidCoords(p)),
    [nearestStock, warehouseById],
  );

  const visibleMarkers = useMemo(
    () => getVisibleMarkers(points, statusFilter, typeFilter, selectedOrigin, candidatePoints, selectedMarker),
    [points, statusFilter, typeFilter, selectedOrigin, candidatePoints, selectedMarker],
  );

  const renderablePoints = useMemo(
    () => visibleMarkers.map(p => ({ point: p, nearestStock: p.type === 'warehouse' ? stockById[p.id] : undefined })),
    [stockById, visibleMarkers],
  );

  const viewportDefaultPoints = useMemo(
    () => points.filter(p => typeFilter === 'all' || p.type === typeFilter).filter(hasValidCoords),
    [points, typeFilter],
  );

  const hasSelection = Boolean(selectedOrigin || selectedMarker);

  const resetSelection = () => {
    setSelectedOriginId(null);
    setSelectedMarkerId(null);
    setPanelOpen(false);
    setViewportMode('default');
    clearStock();
  };

  const handleSelect = (p: MapPoint | null) => {
    if (!p) { resetSelection(); return; }
    if (compact) {
      navigate(`/map?focusId=${p.id}&focusType=${p.type}`);
      return;
    }
    setSelectedMarkerId(p.id);
    setPanelOpen(true);
    if (p.type === 'customer') setSelectedOriginId(p.id);
    setViewportMode('selected');
  };

  return (
    <div className="relative h-full w-full overflow-hidden rounded-xl border border-border">
      {/* Loading overlay */}
      {isLoading && points.length === 0 && (
        <div className="absolute inset-0 z-[2000] flex items-center justify-center bg-background/80">
          <div className="flex items-center gap-3 text-sm text-text-muted">
            <span className="h-4 w-4 animate-spin rounded-full border-2 border-border border-t-primary" />
            Loading map…
          </div>
        </div>
      )}

      {/* Hint when no selection */}
      {!compact && !selectedOrigin && !panelOpen && (
        <div className="absolute bottom-6 left-1/2 z-[1000] -translate-x-1/2">
          <div className="flex items-center gap-2 rounded-full border border-border bg-background/90 px-4 py-2 text-xs text-text-muted shadow backdrop-blur">
            <MapPin size={12} />
            Click a delivery point to find nearest stock
          </div>
        </div>
      )}

      {/* Reset selection button — shown when something is selected */}
      {hasSelection && (
        <div className="absolute left-4 top-4 z-[1000]">
          <button
            type="button"
            onClick={resetSelection}
            aria-label="Reset selection"
            className="flex items-center gap-1.5 rounded-xl border border-border bg-background/90 px-3 py-1.5 text-xs text-text-muted shadow backdrop-blur transition-colors hover:bg-surface hover:text-text"
          >
            <RotateCcw size={11} />
            Reset
          </button>
        </div>
      )}

      {/* Side panel */}
      {panelOpen && selectedMarker && (
        <SidePanel
          point={selectedMarker}
          originPoint={selectedOrigin}
          nearestStock={nearestStock}
          isLoadingStock={loadingStock}
          stockError={stockError}
          resourceSelected={Boolean(selectedResourceId)}
          neededQty={neededQty}
          stockById={stockById}
          onWarehouseSelect={(id) => {
            const p = warehouseById[id];
            if (p) { setSelectedMarkerId(p.id); setPanelOpen(true); }
          }}
          onClose={resetSelection}
        />
      )}

      {/* Map */}
      <MapContainer
        center={DEFAULT_CENTER}
        zoom={DEFAULT_ZOOM}
        style={{ height: '100%', width: '100%' }}
        zoomControl={false}
      >
        <TileLayer
          url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://carto.com/">CARTO</a>'
          subdomains="abcd"
          maxZoom={20}
        />
        <MarkersLayer
          points={renderablePoints}
          selectedId={selectedMarkerId}
          neededQty={neededQty}
          onSelect={handleSelect}
        />
        <ViewportController
          initialPoints={viewportDefaultPoints}
          selectedPoint={selectedMarker}
          candidatePoints={candidatePoints}
          mode={viewportMode}
        />
        <ZoomControl />
      </MapContainer>
    </div>
  );
}
