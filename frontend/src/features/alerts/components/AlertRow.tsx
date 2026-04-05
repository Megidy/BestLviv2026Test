import { Fragment } from 'react';
import { Link } from 'react-router-dom';
import { Map } from 'lucide-react';

import type {
  AlertReasoning,
  AlertWithReasoning,
} from '@/features/alerts/api/alertsApi';
import type { RebalancingProposal } from '@/shared/api';
import { Badge } from '@/shared/ui/Badge';
import { Button } from '@/shared/ui/Button';
import {
  alertTone,
  formatDateTime,
  formatPercent,
  formatRelativeCountdown,
} from '@/shared/lib/formatters';
import {
  TableCell,
  TableRow,
} from '@/shared/ui/Table';

type AlertRowProps = {
  alert: AlertWithReasoning;
  proposal?: RebalancingProposal | null;
  expanded: boolean;
  pointNameById: Record<number, string>;
  resourceNameById: Record<number, string>;
  isMutating: boolean;
  isOnline: boolean;
  onToggleExpand: (alert: AlertWithReasoning) => Promise<void>;
  onApproveProposal: (proposalId: number) => void;
  onDismissProposal: (proposalId: number) => void;
  onDismissAlert: (alertId: number) => void;
};

function renderSuggestedAction(reasoning: AlertReasoning, proposal?: RebalancingProposal | null) {
  if (proposal?.status === 'pending') {
    return 'Review the proposed warehouse transfer before the predicted shortage window.';
  }

  return reasoning.suggestedAction;
}

export function AlertRow({
  alert,
  proposal,
  expanded,
  pointNameById,
  resourceNameById,
  isMutating,
  isOnline,
  onToggleExpand,
  onApproveProposal,
  onDismissProposal,
  onDismissAlert,
}: AlertRowProps) {
  return (
    <Fragment key={alert.id}>
      <TableRow
        className="cursor-pointer hover:bg-accent/60"
        onClick={() => {
          void onToggleExpand(alert);
        }}
      >
        <TableCell className="font-medium">
          {pointNameById[alert.point_id] ?? `Point #${alert.point_id}`}
        </TableCell>
        <TableCell>
          {resourceNameById[alert.resource_id] ?? `Resource #${alert.resource_id}`}
        </TableCell>
        <TableCell>
          <Badge tone={alertTone(alert)}>{formatPercent(alert.confidence)}</Badge>
        </TableCell>
        <TableCell className="text-text-muted">
          {formatRelativeCountdown(alert.predicted_shortfall_at)}
        </TableCell>
        <TableCell className="max-w-72">
          <div className="space-y-1">
            <p className="line-clamp-2 text-sm text-text">
              {alert.reasoning.summary}
            </p>
            <Badge tone="info">{formatPercent(alert.confidence)} confidence</Badge>
          </div>
        </TableCell>
        <TableCell className="text-text-muted">{alert.status}</TableCell>
        <TableCell>
          <div
            className="flex justify-end gap-2"
            onClick={(event) => event.stopPropagation()}
          >
            {alert.proposal_id ? (
              <>
                <Button
                  size="sm"
                  variant="outline"
                  disabled={isMutating || !isOnline}
                  title={!isOnline ? 'Not available offline' : undefined}
                  className="border-success/50 text-success hover:bg-success/10 hover:border-success"
                  onClick={() => onApproveProposal(alert.proposal_id!)}
                >
                  Approve
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  disabled={isMutating || !isOnline}
                  title={!isOnline ? 'Not available offline' : undefined}
                  className="border-danger/50 text-danger hover:bg-danger/10 hover:border-danger"
                  onClick={() => onDismissProposal(alert.proposal_id!)}
                >
                  Reject
                </Button>
              </>
            ) : null}
            <Button
              size="sm"
              variant="outline"
              disabled={isMutating || !isOnline}
              title={!isOnline ? 'Not available offline' : undefined}
              className="border-warning/50 text-warning hover:bg-warning/10 hover:border-warning"
              onClick={() => onDismissAlert(alert.id)}
            >
              Dismiss
            </Button>
            <Button asChild size="sm" variant="outline">
              <Link to={`/map?focusId=${alert.point_id}&focusType=customer`}><Map size={15} /></Link>
            </Button>
          </div>
        </TableCell>
      </TableRow>

      {expanded ? (
        <TableRow>
          <TableCell colSpan={7} className="bg-surface/30">
            <div className="space-y-4 p-2">
              <div className="grid gap-3 md:grid-cols-2">
                <div className="rounded-xl border border-border bg-background/60 p-3">
                  <p className="text-xs uppercase tracking-[0.18em] text-text-muted">
                    What is happening
                  </p>
                  <p className="mt-2 text-sm text-text">
                    {alert.reasoning.demandTrend}
                  </p>
                </div>
                <div className="rounded-xl border border-border bg-background/60 p-3">
                  <p className="text-xs uppercase tracking-[0.18em] text-text-muted">
                    When it may happen
                  </p>
                  <p className="mt-2 text-sm text-text">
                    {alert.reasoning.timePrediction}
                  </p>
                </div>
              </div>

              <div className="rounded-xl border border-border bg-background/60 p-3">
                <p className="text-xs uppercase tracking-[0.18em] text-text-muted">
                  Why the AI flagged this
                </p>
                <p className="mt-2 text-sm text-text">{alert.reasoning.full}</p>
              </div>

              <div className="flex flex-wrap items-center gap-3">
                <Badge tone={alertTone(alert)}>
                  Confidence {formatPercent(alert.confidence)}
                </Badge>
                <span className="text-sm text-text-muted">
                  Suggested action: {renderSuggestedAction(alert.reasoning, proposal)}
                </span>
              </div>

              {proposal ? (
                <div className="space-y-3 rounded-xl border border-border bg-background/40 p-3">
                  <div className="flex flex-wrap items-center gap-3">
                    <Badge tone="info">{proposal.status}</Badge>
                    <span className="text-sm text-text-muted">
                      Created {formatDateTime(proposal.created_at)}
                    </span>
                  </div>
                  {(proposal.transfers ?? []).length > 0 ? (
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
                  ) : (
                    <p className="text-sm text-text-muted">
                      No transfer details available for this proposal yet.
                    </p>
                  )}
                </div>
              ) : null}
            </div>
          </TableCell>
        </TableRow>
      ) : null}
    </Fragment>
  );
}
