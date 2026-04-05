import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { Map } from 'lucide-react';

import { useAlerts } from '@/features/alerts/hooks/useAlerts';
import { useNetwork } from '@/shared/hooks/useNetwork';
import { AlertRow } from '@/features/alerts/components/AlertRow';
import { useInventory } from '@/features/inventory/hooks/useInventory';
import { useMap } from '@/features/map/hooks/useMap';
import { Button } from '@/shared/ui/Button';
import { Badge } from '@/shared/ui/Badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/shared/ui/Card';
import { Skeleton, SkeletonRow } from '@/shared/ui/Skeleton';
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
  const { alerts, proposals, isLoading, isMutating, error, notice, pendingActionKeys, loadProposal, dismissAlert, approveProposal, dismissProposal, runAi } =
    useAlerts();
  const { isOnline } = useNetwork();
  const { points } = useMap();
  // Fetch from warehouse 1 to resolve resource names across all resource IDs
  const { items } = useInventory({
    locationId: 1,
    page: 1,
    pageSize: 30,
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
        <Button
          size="sm"
          onClick={() => void runAi()}
          disabled={isMutating || !isOnline}
          title={!isOnline ? 'Not available offline' : undefined}
        >
          Run predictive AI
        </Button>
      </div>

      {notice ? (
        <div className="fixed bottom-6 right-6 z-[9999] animate-fade-in rounded-xl border border-warning/30 bg-surface/95 px-4 py-3 text-sm text-warning shadow-card backdrop-blur-md">
          {notice}
        </div>
      ) : null}

      <Card>
        <CardHeader>
          <CardTitle>Alert queue</CardTitle>
        </CardHeader>
        <CardContent>
          {/* Mobile card list — hidden on lg+ */}
          <div className="space-y-3 lg:hidden">
            {isLoading ? (
              Array.from({ length: 3 }).map((_, i) => (
                <div key={i} className="rounded-xl border border-border bg-surface/50 p-4">
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0 space-y-1.5">
                      <Skeleton className="h-4 w-32" />
                      <Skeleton className="h-3 w-24" />
                    </div>
                    <Skeleton className="h-5 w-14" />
                  </div>
                  <Skeleton className="mt-3 h-3 w-40" />
                  <Skeleton className="mt-2 h-8 w-full" />
                  <div className="mt-3 flex gap-2 border-t border-border pt-3">
                    <Skeleton className="h-7 w-16" />
                    <Skeleton className="h-7 w-16" />
                    <Skeleton className="h-7 w-16" />
                  </div>
                </div>
              ))
            ) : error ? (
              <p className="py-10 text-center text-sm text-danger">{error}</p>
            ) : alerts.length === 0 ? (
              <p className="py-10 text-center text-sm text-text-muted">No predictive alerts are currently open.</p>
            ) : (
              alerts.map((alert) => {
                const isExpanded = expandedAlertId === alert.id;
                const canResolveAlert = alert.status === 'open';
                const canApproveProposal = Boolean(
                  alert.proposal_id &&
                    canResolveAlert &&
                    proposals[alert.proposal_id]?.status !== 'approved' &&
                    proposals[alert.proposal_id]?.status !== 'dismissed',
                );
                const canDismissProposal = Boolean(
                  alert.proposal_id &&
                    canResolveAlert &&
                    proposals[alert.proposal_id]?.status !== 'dismissed' &&
                    proposals[alert.proposal_id]?.status !== 'approved',
                );

                return (
                  <div
                    key={alert.id}
                    className={`rounded-xl border border-border bg-surface/50 p-4 ${
                      canResolveAlert ? '' : 'opacity-60'
                    }`}
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
                      <span className="capitalize">
                        {(() => {
                          const p = alert.proposal_id ? proposals[alert.proposal_id] : undefined;
                          if (alert.status === 'dismissed') return 'Dismissed';
                          if (alert.status === 'resolved') return 'Resolved';
                          if (!alert.proposal_id || p === undefined || p === null) return 'Open';
                          if (p.status === 'approved') return 'Approved';
                          if (p.status === 'dismissed') return 'Proposal rejected';
                          return 'Awaiting approval';
                        })()}
                      </span>
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
                      {canApproveProposal ? (
                        <>
                          <Button
                            size="sm"
                            variant="outline"
                            disabled={!isOnline || Boolean(pendingActionKeys[`approve-proposal:${alert.proposal_id}`])}
                            title={!isOnline ? 'Not available offline' : undefined}
                            className="border-success/50 text-success hover:bg-success/10 hover:border-success"
                            onClick={() => void approveProposal(alert.proposal_id!)}
                          >
                            {pendingActionKeys[`approve-proposal:${alert.proposal_id}`]
                              ? 'Approving…'
                              : 'Approve'}
                          </Button>
                        </>
                      ) : null}
                      {canDismissProposal ? (
                        <>
                          <Button
                            size="sm"
                            variant="outline"
                            disabled={!isOnline || Boolean(pendingActionKeys[`dismiss-proposal:${alert.proposal_id}`])}
                            title={!isOnline ? 'Not available offline' : undefined}
                            className="border-danger/50 text-danger hover:bg-danger/10 hover:border-danger"
                            onClick={() => void dismissProposal(alert.proposal_id!)}
                          >
                            {pendingActionKeys[`dismiss-proposal:${alert.proposal_id}`]
                              ? 'Rejecting…'
                              : 'Reject'}
                          </Button>
                        </>
                      ) : null}
                      <Button
                        size="sm"
                        variant="outline"
                        disabled={!isOnline || !canResolveAlert || Boolean(pendingActionKeys[`dismiss-alert:${alert.id}`])}
                        title={!isOnline ? 'Not available offline' : undefined}
                        className="border-warning/50 text-warning hover:bg-warning/10 hover:border-warning"
                        onClick={() => void dismissAlert(alert.id)}
                      >
                        {pendingActionKeys[`dismiss-alert:${alert.id}`]
                          ? 'Dismissing…'
                          : 'Dismiss'}
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
                  Array.from({ length: 5 }).map((_, i) => (
                    <SkeletonRow key={i} cols={['w-24', 'w-20', 'w-14', 'w-20', 'w-48', 'w-20', 'w-28']} />
                  ))
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
                        pendingActionKeys={pendingActionKeys}
                        isOnline={isOnline}
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
