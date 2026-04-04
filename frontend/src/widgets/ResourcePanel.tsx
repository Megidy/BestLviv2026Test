import { Link } from 'react-router-dom';

import type { LocationSummary } from '@/shared/config/operations-data';
import { Badge } from '@/shared/ui/Badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/shared/ui/Card';

type ResourcePanelProps = {
  items: LocationSummary[];
};

export function ResourcePanel({ items }: ResourcePanelProps) {
  return (
    <Card className="h-full">
      <CardHeader>
        <CardTitle>Locations</CardTitle>
      </CardHeader>
      <CardContent className="space-y-2.5">
        {items.map((item) => (
          <Link
            key={item.id}
            to={`/resource/${item.alerts > 0 ? 'r5' : 'r1'}`}
            className="group flex items-center justify-between rounded-xl border border-border/60 bg-surface/50 px-4 py-3.5 transition-all duration-200 hover:border-primary/20 hover:bg-white/[0.03] hover:shadow-glow"
          >
            <div>
              <p className="text-sm font-medium text-text group-hover:text-primary transition-colors duration-200">
                {item.name}
              </p>
              <p className="text-xs text-text-muted">
                {item.resources} resources · {item.lastSync}
              </p>
            </div>
            <div className="flex items-center gap-2">
              {item.alerts > 0 ? (
                <span className="flex items-center gap-1 text-xs text-danger">
                  <span className="h-1.5 w-1.5 rounded-full bg-danger animate-pulse" />
                  {item.alerts}
                </span>
              ) : null}
              <Badge tone={item.tone}>{item.tone}</Badge>
            </div>
          </Link>
        ))}
      </CardContent>
    </Card>
  );
}
