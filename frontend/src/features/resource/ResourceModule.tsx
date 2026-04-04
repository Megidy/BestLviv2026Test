import { Link, useParams } from 'react-router-dom';

import {
  inventoryItems,
  resourceActivities,
} from '@/shared/config/operations-data';
import { Badge } from '@/shared/ui/Badge';
import { Button } from '@/shared/ui/Button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/shared/ui/Card';

export function ResourceModule() {
  const { id } = useParams();
  const resource =
    inventoryItems.find((item) => item.id === id) ?? inventoryItems[0];
  const activity = resourceActivities[resource.id] ?? resourceActivities.r1;

  return (
    <div className="space-y-5 animate-slide-up">
      <div className="flex items-center justify-between gap-4">
        <div>
          <p className="text-xs uppercase tracking-[0.2em] text-text-muted">
            Resource
          </p>
          <h1 className="mt-2 text-2xl font-semibold">{resource.name}</h1>
          <p className="mt-1 text-sm text-text-muted">
            Updated at {resource.updated}
          </p>
        </div>
        <Badge tone={resource.tone}>{resource.tone}</Badge>
      </div>

      <div className="grid gap-5 xl:grid-cols-[minmax(0,2fr)_minmax(320px,1fr)]">
        <div className="space-y-5">
          <Card>
            <CardHeader>
              <CardTitle>Current stock</CardTitle>
              <CardDescription>
                Real-time operational state of this resource.
              </CardDescription>
            </CardHeader>
            <CardContent className="grid gap-4 md:grid-cols-2">
              <div className="rounded-xl border border-border bg-surface/60 p-4 transition-colors hover:bg-accent/40">
                <p className="text-sm text-text-muted">Quantity</p>
                <p className="mt-2 text-3xl font-semibold">
                  {resource.quantity} {resource.unit}
                </p>
              </div>
              <div className="rounded-xl border border-border bg-surface/60 p-4 transition-colors hover:bg-accent/40">
                <p className="text-sm text-text-muted">Location</p>
                <p className="mt-2 text-xl font-semibold">
                  {resource.location}
                </p>
              </div>
              <div className="rounded-xl border border-border bg-surface/60 p-4 transition-colors hover:bg-accent/40">
                <p className="text-sm text-text-muted">Category</p>
                <p className="mt-2 text-xl font-semibold">
                  {resource.category}
                </p>
              </div>
              <div className="rounded-xl border border-border bg-surface/60 p-4 transition-colors hover:bg-accent/40">
                <p className="text-sm text-text-muted">Threshold</p>
                <p className="mt-2 text-xl font-semibold">
                  100 {resource.unit}
                </p>
              </div>
            </CardContent>
          </Card>

          <div className="flex flex-wrap gap-3">
            <Button>Update demand</Button>
            <Button variant="outline">Mark urgent</Button>
            <Button variant="outline">Confirm delivery</Button>
            <Button asChild variant="ghost">
              <Link to="/inventory">Back to inventory</Link>
            </Button>
          </div>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Activity</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {activity.map((entry) => (
              <div
                key={`${entry.action}-${entry.time}`}
                className="rounded-xl border border-border bg-surface/60 p-4 transition-colors hover:bg-accent/40"
              >
                <p className="text-sm font-medium">{entry.action}</p>
                <p className="mt-1 text-xs text-text-muted">
                  {entry.user} · {entry.time}
                </p>
              </div>
            ))}
            <p className="flex items-center gap-2 text-xs text-text-muted">
              <span className="h-1.5 w-1.5 rounded-full bg-success animate-pulse" />
              Sync status: synchronized
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
