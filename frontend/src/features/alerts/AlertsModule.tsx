import { Fragment, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { useAlerts } from '@/features/alerts/hooks/useAlerts';
import { useInventory } from '@/features/inventory/hooks/useInventory';
import { useMap } from '@/features/map/hooks/useMap';
import { Badge } from '@/shared/ui/Badge';
import { Button } from '@/shared/ui/Button';
import {
  alertTone,
  formatDateTime,
  formatPercent,
  formatRelativeCountdown,
} from '@/shared/lib/formatters';
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
  const { user } = useAuth();
  const { alerts, proposals, isLoading, isMutating, error, loadProposal, dismissAlert, approveProposal, dismissProposal, runAi } =
    useAlerts();
  const { points } = useMap();
  const { items } = useInventory({
    enabled: Boolean(user?.location_id),
    locationId: user?.location_id ?? 0,
    page: 1,
    pageSize: 50,
  });
  const [expandedAlertId, setExpandedAlertId] = useState<number | null>(null);

  const pointNameById = useMemo(
    () => Object.fromEntries(points.map((point) => [point.id, point.name])),
    [points],
  );
  const resourceNameById = useMemo(
    () => Object.fromEntries(items.map((item) => [item.resourceId, item.name])),
    [items],
  );
  const summary = useMemo(
    () => ({
      open: alerts.length,
      pending: alerts.filter((item) => item.proposal_id).length,
    }),
    [alerts],
  );

  return (
    <div className="space-y-5 animate-slide-up">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <p className="flex items-center gap-2 text-sm text-text-muted">
          <span className="h-1.5 w-1.5 rounded-full bg-danger animate-pulse" />
          {summary.open} open alerts · {summary.pending} proposals available
        </p>
        <Button size="sm" onClick={() => void runAi()} disabled={isMutating}>
          Run predictive AI
        </Button>
      </div>

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
                <TableHead>Confidence</TableHead>
                <TableHead>Shortage ETA</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Proposal</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                <TableRow>
                  <TableCell className="py-10 text-center text-text-muted" colSpan={7}>
                    Loading alerts…
                  </TableCell>
                </TableRow>
              ) : error ? (
                <TableRow>
                  <TableCell className="py-10 text-center text-danger" colSpan={7}>
                    {error}
                  </TableCell>
                </TableRow>
              ) : alerts.length === 0 ? (
                <TableRow>
                  <TableCell className="py-10 text-center text-text-muted" colSpan={7}>
                    No predictive alerts are currently open.
                  </TableCell>
                </TableRow>
              ) : (
                alerts.map((alert) => {
                  const proposal =
                    alert.proposal_id !== undefined
                      ? proposals[alert.proposal_id]
                      : undefined;

                  return (
                    <Fragment key={alert.id}>
                      <TableRow className="hover:bg-accent/60">
                        <TableCell className="font-medium">
                          {pointNameById[alert.point_id] ?? `Point #${alert.point_id}`}
                        </TableCell>
                        <TableCell>
                          {resourceNameById[alert.resource_id] ??
                            `Resource #${alert.resource_id}`}
                        </TableCell>
                        <TableCell>
                          <Badge tone={alertTone(alert)}>
                            {formatPercent(alert.confidence)}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-text-muted">
                          {formatRelativeCountdown(alert.predicted_shortfall_at)}
                        </TableCell>
                        <TableCell className="text-text-muted">
                          {alert.status}
                        </TableCell>
                        <TableCell>
                          {alert.proposal_id ? (
                            <Button
                              size="sm"
                              variant="ghost"
                              onClick={async () => {
                                await loadProposal(alert.proposal_id!);
                                setExpandedAlertId((current) =>
                                  current === alert.id ? null : alert.id,
                                );
                              }}
                            >
                              {expandedAlertId === alert.id ? 'Hide' : 'View'}
                            </Button>
                          ) : (
                            <span className="text-sm text-text-muted">None</span>
                          )}
                        </TableCell>
                        <TableCell>
                          <div className="flex justify-end gap-2">
                            {alert.proposal_id ? (
                              <>
                                <Button
                                  size="sm"
                                  variant="ghost"
                                  disabled={isMutating}
                                  onClick={() => void approveProposal(alert.proposal_id!)}
                                >
                                  Approve
                                </Button>
                                <Button
                                  size="sm"
                                  variant="ghost"
                                  disabled={isMutating}
                                  onClick={() => void dismissProposal(alert.proposal_id!)}
                                >
                                  Reject
                                </Button>
                              </>
                            ) : null}
                            <Button
                              size="sm"
                              variant="outline"
                              disabled={isMutating}
                              onClick={() => void dismissAlert(alert.id)}
                            >
                              Dismiss
                            </Button>
                            <Button asChild size="sm" variant="ghost">
                              <Link to="/map">Map</Link>
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>

                      {expandedAlertId === alert.id && proposal ? (
                        <TableRow>
                          <TableCell colSpan={7} className="bg-surface/30">
                            <div className="space-y-3 p-2">
                              <div className="flex flex-wrap items-center gap-3">
                                <Badge tone="info">{proposal.status}</Badge>
                                <span className="text-sm text-text-muted">
                                  Created {formatDateTime(proposal.created_at)}
                                </span>
                              </div>
                              {alert.rationale ? (
                                <p className="text-sm text-text-muted">
                                  {alert.rationale}
                                </p>
                              ) : null}
                              <div className="space-y-2">
                                {(proposal.transfers ?? []).map((transfer) => (
                                  <div
                                    key={transfer.id}
                                    className="rounded-xl border border-border bg-background/60 p-3"
                                  >
                                    <p className="text-sm font-medium">
                                      {pointNameById[transfer.from_warehouse_id] ??
                                        `Warehouse #${transfer.from_warehouse_id}`}
                                    </p>
                                    <p className="mt-1 text-xs text-text-muted">
                                      {transfer.quantity} units ·{' '}
                                      {transfer.estimated_arrival_hours.toFixed(1)}h ETA
                                    </p>
                                  </div>
                                ))}
                              </div>
                            </div>
                          </TableCell>
                        </TableRow>
                      ) : null}
                    </Fragment>
                  );
                })
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
