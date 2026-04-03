import { useMemo } from 'react';

import { alerts } from '@/shared/config/operations-data';
import { Badge } from '@/shared/ui/Badge';
import { Button } from '@/shared/ui/Button';
import { Card, CardContent, CardHeader, CardTitle } from '@/shared/ui/Card';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/shared/ui/Table';

export function AlertsModule() {
  const summary = useMemo(
    () => ({
      open: alerts.filter((item) => item.status === 'open').length,
      pending: alerts.filter((item) => item.status === 'pending').length,
    }),
    [],
  );

  return (
    <div className="space-y-5 animate-slide-up">
      <p className="flex items-center gap-2 text-sm text-text-muted">
        <span className="h-1.5 w-1.5 rounded-full bg-danger animate-pulse" />
        {summary.open} open alerts · {summary.pending} pending review
      </p>

      <Card>
        <CardHeader>
          <CardTitle>Alert queue</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Location</TableHead>
                <TableHead>Resource</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Severity</TableHead>
                <TableHead>ETA</TableHead>
                <TableHead>Owner</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {alerts.map((alert) => (
                <TableRow key={alert.id} className="hover:bg-accent/60">
                  <TableCell className="font-medium">
                    {alert.location}
                  </TableCell>
                  <TableCell>{alert.resource}</TableCell>
                  <TableCell>
                    <Badge
                      tone={alert.type === 'Predicted' ? 'info' : 'neutral'}
                    >
                      {alert.type}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <Badge tone={alert.severity}>{alert.severity}</Badge>
                  </TableCell>
                  <TableCell className="text-text-muted">{alert.eta}</TableCell>
                  <TableCell className="text-text-muted">
                    {alert.owner}
                  </TableCell>
                  <TableCell className="text-text-muted">
                    {alert.status}
                  </TableCell>
                  <TableCell>
                    <div className="flex justify-end gap-2">
                      <Button size="sm" variant="ghost">
                        Approve
                      </Button>
                      <Button size="sm" variant="ghost">
                        Dismiss
                      </Button>
                      <Button size="sm" variant="outline">
                        Map
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
