import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { Map } from 'lucide-react';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { useAlerts } from '@/features/alerts/hooks/useAlerts';
import { AlertRow } from '@/features/alerts/components/AlertRow';
import { useInventory } from '@/features/inventory/hooks/useInventory';
import { useMap } from '@/features/map/hooks/useMap';
import { Button } from '@/shared/ui/Button';
import { Badge } from '@/shared/ui/Badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/shared/ui/Card';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/shared/ui/Table';
import {
  alertTone,
  formatPercent,
  formatRelativeCountdown,
} from '@/shared/lib/formatters';

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
    () => Object.fromEntries(
      points.filter((p) => p.type === 'customer').map((point) => [point.id, point.name]),
    ),
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
          {/* Mobile card list — hidden on lg+ */}
          <div className="space-y-3 lg:hidden">
            {isLoading ? (
              <p className="py-10 text-center text-sm text-text-muted">Loading alerts…</p>
            ) : error ? (
              <p className="py-10 text-center text-sm text-danger">{error}</p>
            ) : alerts.length === 0 ? (
              <p className="py-10 text-center text-sm text-text-muted">No predictive alerts are currently open.</p>
            ) : (
              alerts.map((alert) => {
                const isExpanded = expandedAlertId === alert.id;

                return (
                  <div
                    key={alert.id}
                    className="rounded-xl border border-border bg-surface/50 p-4"
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="min-w-0">
                        <p className="truncate text-sm font-semibold text-text">
                          {pointNameById[alert.point_id] ?? `Point #${alert.point_id}`}
                        </p>
                        <p className="mt-0.5 truncate text-xs text-text-muted">
                          {resourceNameById[alert.resource_id] ?? `Resource #${alert.resource_id}`}
                        </p>
                      </div>
                      <Badge tone={alertTone(alert)}>{formatPercent(alert.confidence)}</Badge>
                    </div>

                    <div className="mt-3 flex flex-wrap items-center gap-2 text-xs text-text-muted">
                      <span>ETA: {formatRelativeCountdown(alert.predicted_shortfall_at)}</span>
                      <span>·</span>
                      <span className="capitalize">{alert.status}</span>
                    </div>

                    <p className="mt-2 line-clamp-2 text-sm text-text">{alert.reasoning.summary}</p>

                    {isExpanded ? (
                      <div className="mt-3 space-y-2 border-t border-border pt-3">
                        <div className="rounded-xl border border-border bg-background/60 p-3">
                          <p className="text-xs uppercase tracking-[0.18em] text-text-muted">What is happening</p>
                          <p className="mt-1 text-sm text-text">{alert.reasoning.demandTrend}</p>
                        </div>
                        <div className="rounded-xl border border-border bg-background/60 p-3">
                          <p className="text-xs uppercase tracking-[0.18em] text-text-muted">When it may happen</p>
                          <p className="mt-1 text-sm text-text">{alert.reasoning.timePrediction}</p>
                        </div>
                        <div className="rounded-xl border border-border bg-background/60 p-3">
                          <p className="text-xs uppercase tracking-[0.18em] text-text-muted">Why the AI flagged this</p>
                          <p className="mt-1 text-sm text-text">{alert.reasoning.full}</p>
                        </div>
                      </div>
                    ) : null}

                    <div className="mt-3 flex flex-wrap items-center gap-2 border-t border-border pt-3">
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={async () => {
                          if (alert.proposal_id) await loadProposal(alert.proposal_id);
                          setExpandedAlertId((cur) => cur === alert.id ? null : alert.id);
                        }}
                      >
                        {isExpanded ? 'Collapse' : 'Details'}
                      </Button>
                      {alert.proposal_id ? (
                        <>
                          <Button
                            size="sm"
                            variant="outline"
                            disabled={isMutating}
                            className="border-success/50 text-success hover:bg-success/10 hover:border-success"
                            onClick={() => void approveProposal(alert.proposal_id!)}
                          >
                            Approve
                          </Button>
                          <Button
                            size="sm"
                            variant="outline"
                            disabled={isMutating}
                            className="border-danger/50 text-danger hover:bg-danger/10 hover:border-danger"
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
                        className="border-warning/50 text-warning hover:bg-warning/10 hover:border-warning"
                        onClick={() => void dismissAlert(alert.id)}
                      >
                        Dismiss
                      </Button>
                      <Button asChild size="sm" variant="outline">
                        <Link to={`/map?focusId=${alert.point_id}&focusType=customer`}>
                          <Map size={15} />
                        </Link>
                      </Button>
                    </div>
                  </div>
                );
              })
            )}
          </div>

          {/* Desktop table — hidden on mobile/tablet */}
          <div className="hidden lg:block">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Location</TableHead>
                  <TableHead>Resource</TableHead>
                  <TableHead>Confidence</TableHead>
                  <TableHead>Shortage ETA</TableHead>
                  <TableHead>Reasoning</TableHead>
                  <TableHead>Status</TableHead>
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
                      <AlertRow
                        key={alert.id}
                        alert={alert}
                        proposal={proposal}
                        expanded={expandedAlertId === alert.id}
                        pointNameById={pointNameById}
                        resourceNameById={resourceNameById}
                        isMutating={isMutating}
                        onToggleExpand={async (selectedAlert) => {
                          if (selectedAlert.proposal_id) {
                            await loadProposal(selectedAlert.proposal_id);
                          }
                          setExpandedAlertId((current: number | null) =>
                            current === selectedAlert.id ? null : selectedAlert.id,
                          );
                        }}
                        onApproveProposal={(proposalId) => void approveProposal(proposalId)}
                        onDismissProposal={(proposalId) => void dismissProposal(proposalId)}
                        onDismissAlert={(alertId) => void dismissAlert(alertId)}
                      />
                    );
                  })
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
