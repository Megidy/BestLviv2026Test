import { useMemo, useState } from 'react';

import { useAuth } from '@/features/auth/hooks/useAuth';
import { useAlerts } from '@/features/alerts/hooks/useAlerts';
import { AlertRow } from '@/features/alerts/components/AlertRow';
import { useInventory } from '@/features/inventory/hooks/useInventory';
import { useMap } from '@/features/map/hooks/useMap';
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
                      onApproveProposal={(proposalId) =>
                        void approveProposal(proposalId)
                      }
                      onDismissProposal={(proposalId) =>
                        void dismissProposal(proposalId)
                      }
                      onDismissAlert={(alertId) => void dismissAlert(alertId)}
                    />
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
