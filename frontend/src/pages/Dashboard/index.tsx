import { AlertTriangle, MapPin, Package, ShieldAlert } from 'lucide-react';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { useAlerts } from '@/features/alerts/hooks/useAlerts';
import { useInventory } from '@/features/inventory/hooks/useInventory';
import { useMap } from '@/features/map/hooks/useMap';
import { useNetwork } from '@/shared/hooks/useNetwork';
import { formatDateTime } from '@/shared/lib/formatters';
import { Card, CardContent } from '@/shared/ui/Card';
import { cn } from '@/shared/lib/cn';
import { MapPanel } from '@/widgets/MapPanel';
import { ResourcePanel } from '@/widgets/ResourcePanel';

export function DashboardPage() {
  const { user } = useAuth();
  const { points, isLoading: isMapLoading, error: mapError } = useMap();
  const {
    alerts,
    isLoading: isAlertsLoading,
    error: alertsError,
  } = useAlerts({ pageSize: 10 });
  const {
    items,
    isLoading: isInventoryLoading,
    error: inventoryError,
  } = useInventory({
    enabled: Boolean(user?.location_id),
    locationId: user?.location_id ?? 0,
    page: 1,
    pageSize: 20,
  });
  const isLoading = isMapLoading || isAlertsLoading || isInventoryLoading;
  const error = mapError ?? alertsError ?? inventoryError;
  const { isOnline } = useNetwork();

  const kpis = [
    {
      label: 'Operational points',
      value: points.length,
      color: 'text-primary',
      glow: 'shadow-[0_0_12px_rgba(145,98,29,0.12)]',
      icon: MapPin,
      iconColor: 'text-primary',
      iconBg: 'bg-primary/10',
    },
    {
      label: 'Open alerts',
      value: alerts.length,
      color: 'text-danger',
      glow: 'shadow-[0_0_12px_rgba(160,69,53,0.12)]',
      icon: AlertTriangle,
      iconColor: 'text-danger',
      iconBg: 'bg-danger/10',
    },
    {
      label: 'Resources tracked',
      value: items.length,
      color: 'text-success',
      glow: 'shadow-[0_0_12px_rgba(78,122,81,0.12)]',
      icon: Package,
      iconColor: 'text-success',
      iconBg: 'bg-success/10',
    },
    {
      label: 'Critical points',
      value: points.filter((point) => point.status === 'critical').length,
      color: 'text-warning',
      glow: 'shadow-[0_0_12px_rgba(169,122,32,0.12)]',
      icon: ShieldAlert,
      iconColor: 'text-warning',
      iconBg: 'bg-warning/10',
    },
  ];

  return (
    <div className="space-y-6 animate-slide-up">
      {error ? (
        <Card>
          <CardContent className="py-4 text-sm text-danger">{error}</CardContent>
        </Card>
      ) : null}

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {kpis.map((item) => (
          <Card key={item.label} className={cn('flex min-h-[88px] items-center p-5', item.glow)}>
            <div className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-xl ${item.iconBg}`}>
              <item.icon size={22} className={item.iconColor} />
            </div>
            <div className="ml-4">
              <p className="text-sm text-text-muted">{item.label}</p>
              <p className={`text-3xl font-bold ${item.color}`}>{item.value}</p>
            </div>
          </Card>
        ))}
      </div>

      <div className="grid gap-6 xl:grid-cols-[minmax(0,2fr)_minmax(360px,1fr)]">
        <MapPanel
          title="Location map"
          description="Dispatcher view of operational points."
        />
        <ResourcePanel
          variant="locations"
          items={points
            .filter((point) => point.type === 'warehouse')
            .slice(0, 6)
            .map((point) => ({
              id: point.id,
              name: point.name,
              type: point.type,
              status: point.status,
              alerts: point.alert_count,
            }))}
        />
      </div>

      <Card className="flex min-h-[52px] items-center justify-between px-5">
        <p className="text-sm text-text-muted">
          {!isOnline
            ? 'Viewing cached data'
            : isLoading
              ? 'Synchronizing live data…'
              : `Synchronized: ${formatDateTime(new Date().toISOString())}`}
        </p>
        <span className="flex items-center gap-2 text-sm font-medium text-text-muted">
          <span
            className={cn(
              'h-1.5 w-1.5 rounded-full',
              !isOnline ? 'bg-warning' : 'animate-pulse bg-success',
            )}
          />
          {!isOnline ? 'Offline' : isLoading ? 'Loading' : 'Live'}
        </span>
      </Card>
    </div>
  );
}
