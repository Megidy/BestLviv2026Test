import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { useEffect, useRef, useState } from 'react';
import { MapContainer, TileLayer, useMap } from 'react-leaflet';

import { type MapPoint, type MapPointStatus, getMapPoints } from '@/shared/api/map';
import { Badge } from '@/shared/ui/Badge';

// ── marker colours ────────────────────────────────────────────────────────────
const STATUS_COLOR: Record<MapPointStatus, string> = {
  normal: '#22c55e',
  elevated: '#f59e0b',
  critical: '#ef4444',
  predictive: '#8b5cf6',
};

const STATUS_TONE: Record<MapPointStatus, 'success' | 'warning' | 'danger' | 'info'> = {
  normal: 'success',
  elevated: 'warning',
  critical: 'danger',
  predictive: 'info',
};

function makeIcon(status: MapPointStatus, type: 'warehouse' | 'customer') {
  const color = STATUS_COLOR[status];
  const size = type === 'warehouse' ? 18 : 14;
  const pulse = status === 'critical' ? 'map-marker--pulse-fast' : status === 'elevated' ? 'map-marker--pulse-slow' : '';
  return L.divIcon({
    html: `<span class="map-marker ${pulse}" style="background:${color};width:${size}px;height:${size}px;border-radius:50%;display:block;border:2px solid rgba(255,255,255,0.6);box-shadow:0 0 6px ${color}80"></span>`,
    className: '',
    iconSize: [size, size],
    iconAnchor: [size / 2, size / 2],
  });
}

// ── markers layer (imperative Leaflet, avoids react-leaflet marker icon bug) ──
function MarkersLayer({
  points,
  onSelect,
}: {
  points: MapPoint[];
  onSelect: (p: MapPoint | null) => void;
}) {
  const map = useMap();
  const layerRef = useRef<L.LayerGroup | null>(null);

  useEffect(() => {
    if (layerRef.current) {
      layerRef.current.clearLayers();
    } else {
      layerRef.current = L.layerGroup().addTo(map);
    }

    points.forEach((p) => {
      const marker = L.marker([p.lat, p.lng], { icon: makeIcon(p.status, p.type) });
      marker.on('click', () => onSelect(p));
      layerRef.current!.addLayer(marker);
    });

    return () => {
      layerRef.current?.clearLayers();
    };
  }, [map, points, onSelect]);

  return null;
}

// ── side panel ────────────────────────────────────────────────────────────────
function SidePanel({ point, onClose }: { point: MapPoint; onClose: () => void }) {
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
          ✕
        </button>
      </div>

      <div className="mb-3 flex items-center gap-2">
        <Badge tone={STATUS_TONE[point.status]} className="capitalize">
          {point.status}
        </Badge>
        {point.alert_count > 0 && (
          <span className="text-xs text-text-muted">
            {point.alert_count} open alert{point.alert_count !== 1 ? 's' : ''}
          </span>
        )}
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
    </div>
  );
}

// ── filter bar ────────────────────────────────────────────────────────────────
type Filter = 'all' | MapPointStatus;

function FilterBar({ active, onChange }: { active: Filter; onChange: (f: Filter) => void }) {
  const filters: Filter[] = ['all', 'critical', 'elevated', 'predictive', 'normal'];
  return (
    <div className="absolute left-4 top-4 z-[1000] flex gap-1.5 rounded-xl border border-border bg-background/90 p-1.5 shadow backdrop-blur">
      {filters.map((f) => (
        <button
          key={f}
          onClick={() => onChange(f)}
          className={`rounded-lg px-3 py-1 text-xs font-medium capitalize transition-colors ${
            active === f
              ? 'bg-primary text-background'
              : 'text-text-muted hover:bg-white/5 hover:text-text'
          }`}
        >
          {f}
        </button>
      ))}
    </div>
  );
}

// ── main component ────────────────────────────────────────────────────────────
// Lviv, Ukraine as default centre — adjust to your data
const DEFAULT_CENTER: [number, number] = [49.8397, 24.0297];
const DEFAULT_ZOOM = 10;

export function MapView() {
  const [points, setPoints] = useState<MapPoint[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<MapPoint | null>(null);
  const [filter, setFilter] = useState<Filter>('all');

  useEffect(() => {
    let cancelled = false;

    async function load() {
      try {
        const data = await getMapPoints();
        if (!cancelled) setPoints(data);
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    load();
    const interval = setInterval(load, 30_000);
    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, []);

  const visible = filter === 'all' ? points : points.filter((p) => p.status === filter);

  return (
    <div className="relative h-full w-full overflow-hidden rounded-xl border border-border">
      {loading && points.length === 0 && (
        <div className="absolute inset-0 z-[2000] flex items-center justify-center bg-background/80">
          <span className="text-sm text-text-muted">Loading map…</span>
        </div>
      )}

      <FilterBar active={filter} onChange={setFilter} />

      {selected && (
        <SidePanel point={selected} onClose={() => setSelected(null)} />
      )}

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
        <MarkersLayer points={visible} onSelect={setSelected} />
      </MapContainer>
    </div>
  );
}
