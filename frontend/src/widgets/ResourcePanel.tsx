import { Link } from 'react-router-dom';

import { formatNumber, mapStatusTone } from '@/shared/lib/formatters';
import { Badge } from '@/shared/ui/Badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/shared/ui/Card';

type LocationPanelItem = {
  id: number;
  name: string;
  type: 'warehouse' | 'customer';
  status: 'normal' | 'elevated' | 'critical' | 'predictive';
  alerts: number;
};

type NearestStockPanelItem = {
  warehouseId: number;
  warehouseName: string;
  surplus: number;
  distanceKm: number;
  estimatedArrivalHours: number;
};

type ResourcePanelProps =
  | {
      variant: 'locations';
      items: LocationPanelItem[];
    }
  | {
      variant: 'nearest-stock';
      items: NearestStockPanelItem[];
    };

export function ResourcePanel({ items }: ResourcePanelProps) {
  const safeItems = Array.isArray(items) ? items : [];
  const isNearestStock = safeItems.length > 0 && 'warehouseId' in safeItems[0];
  const nearestStockItems = isNearestStock ? (safeItems as NearestStockPanelItem[]) : [];
  const locationItems = isNearestStock ? [] : (safeItems as LocationPanelItem[]);

  return (
    <Card className="h-full">
      <CardHeader>
        <CardTitle>{isNearestStock ? 'Nearest stock' : 'Locations'}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-2.5">
        {safeItems.length === 0 ? (
          <div className="rounded-xl border border-dashed border-border bg-surface/40 px-4 py-8 text-center text-sm text-text-muted">
            No records available.
          </div>
        ) : isNearestStock ? (
          nearestStockItems.map((item) => (
            <div
              key={item.warehouseId}
              className="flex items-center justify-between rounded-xl border border-border/60 bg-surface/50 px-4 py-3.5"
            >
              <div>
                <p className="text-sm font-medium text-text">{item.warehouseName}</p>
                <p className="text-xs text-text-muted">
                  {formatNumber(item.surplus)} surplus ·{' '}
                  {formatNumber(item.distanceKm)} km
                </p>
              </div>
              <Badge tone="info">
                {formatNumber(item.estimatedArrivalHours)}h ETA
              </Badge>
            </div>
          ))
        ) : (
          locationItems.map((item) => (
            <Link
              key={item.id}
              to="/map"
              className="group flex items-center justify-between rounded-xl border border-border/60 bg-surface/50 px-4 py-3.5 transition-all duration-200 hover:border-primary/20 hover:bg-white/[0.03] hover:shadow-glow"
            >
              <div>
                <p className="text-sm font-medium text-text transition-colors duration-200 group-hover:text-primary">
                  {item.name}
                </p>
                <p className="text-xs capitalize text-text-muted">{item.type}</p>
              </div>
              <div className="flex items-center gap-2">
                {item.alerts > 0 ? (
                  <span className="flex items-center gap-1 text-xs text-danger">
                    <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-danger" />
                    {item.alerts}
                  </span>
                ) : null}
                <Badge tone={mapStatusTone(item.status)}>{item.status}</Badge>
              </div>
            </Link>
          ))
        )}
      </CardContent>
    </Card>
  );
}
