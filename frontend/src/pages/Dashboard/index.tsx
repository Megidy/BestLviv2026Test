import { AlertTriangle, MapPin, Package, ShieldAlert } from 'lucide-react';

import {
  alerts,
  inventoryItems,
  locationSummaries,
} from '@/shared/config/operations-data';
import { Card, CardContent, CardHeader, CardTitle } from '@/shared/ui/Card';
import { cn } from '@/shared/lib/cn';
import { MapPanel } from '@/widgets/MapPanel';
import { ResourcePanel } from '@/widgets/ResourcePanel';

const kpis = [
  {
    label: 'Active locations',
    value: locationSummaries.length,
    color: 'text-primary',
    glow: 'shadow-[0_0_12px_rgba(145,98,29,0.12)]',
    icon: MapPin,
    iconColor: 'text-primary',
    iconBg: 'bg-primary/10',
  },
  {
    label: 'Open alerts',
    value: alerts.filter((item) => item.status === 'open').length,
    color: 'text-danger',
    glow: 'shadow-[0_0_12px_rgba(160,69,53,0.12)]',
    icon: AlertTriangle,
    iconColor: 'text-danger',
    iconBg: 'bg-danger/10',
  },
  {
    label: 'Resources tracked',
    value: inventoryItems.length,
    color: 'text-success',
    glow: 'shadow-[0_0_12px_rgba(78,122,81,0.12)]',
    icon: Package,
    iconColor: 'text-success',
    iconBg: 'bg-success/10',
  },
  {
    label: 'Critical shortages',
    value: inventoryItems.filter((item) => item.tone === 'danger').length,
    color: 'text-warning',
    glow: 'shadow-[0_0_12px_rgba(169,122,32,0.12)]',
    icon: ShieldAlert,
    iconColor: 'text-warning',
    iconBg: 'bg-warning/10',
  },
];

export function DashboardPage() {
  return (
    <div className="space-y-6 animate-slide-up">
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
        <ResourcePanel items={locationSummaries} />
      </div>

      <Card className="flex min-h-[52px] items-center justify-between px-5">
        <p className="text-sm text-text-muted">
          Synchronized: 03 April 2026, 15:36 Europe/Kyiv
        </p>
        <span className="flex items-center gap-2 text-sm font-medium text-text-muted">
          <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-success" />
          Live
        </span>
      </Card>
    </div>
  );
}
