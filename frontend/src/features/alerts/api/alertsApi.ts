import {
  ApiError,
  endpoints,
  request,
  unwrapApiResponse,
  type ApiResponse,
  type PredictiveAlertsResponse,
  type PredictiveAlert,
  type RebalancingProposal,
} from '@/shared/api';
import {
  formatPercent,
  formatRelativeCountdown,
} from '@/shared/lib/formatters';

export type AlertReasoning = {
  summary: string;
  demandTrend: string;
  timePrediction: string;
  confidenceText: string;
  suggestedAction: string;
  full: string;
};

export type AlertWithReasoning = PredictiveAlert & {
  reasoning: AlertReasoning;
};

export class AlertsConflictError extends Error {
  constructor(message = 'This alert has already been resolved') {
    super(message);
    this.name = 'AlertsConflictError';
  }
}

function mapAlertsApiError(caught: unknown): never {
  if (caught instanceof ApiError && caught.statusCode === 409) {
    throw new AlertsConflictError();
  }

  throw caught;
}

function normalizeSentence(value: string | null | undefined) {
  const normalized = value?.replace(/\s+/g, ' ').trim();

  if (!normalized) {
    return '';
  }

  return /[.!?]$/.test(normalized) ? normalized : `${normalized}.`;
}

function buildDemandTrend(alert: PredictiveAlert) {
  const rationale = normalizeSentence(alert.rationale);

  if (rationale) {
    return rationale;
  }

  if (alert.confidence >= 0.85) {
    return 'Demand pressure is rising sharply against current stock coverage.';
  }

  if (alert.confidence >= 0.65) {
    return 'Demand is trending above the expected baseline and is narrowing stock headroom.';
  }

  return 'The model detected early demand pressure that could reduce stock coverage soon.';
}

function buildTimePrediction(alert: PredictiveAlert) {
  const eta = formatRelativeCountdown(alert.predicted_shortfall_at);

  if (eta === 'Due now') {
    return 'Inventory is projected to hit a shortage immediately unless stock is rebalanced.';
  }

  return `Inventory is projected to run out in ${eta}.`;
}

function buildSuggestedAction(alert: PredictiveAlert) {
  if (alert.proposal_id) {
    return 'Review the linked proposal and approve rebalancing if the destination still needs coverage.';
  }

  if (alert.confidence >= 0.85) {
    return 'Escalate now and prepare a replenishment transfer from the nearest warehouse.';
  }

  return 'Monitor the point closely and stage replenishment before the depletion window.';
}

function buildReasoning(alert: PredictiveAlert): AlertReasoning {
  const demandTrend = buildDemandTrend(alert);
  const timePrediction = buildTimePrediction(alert);
  const confidenceText = `AI confidence is ${formatPercent(alert.confidence)}.`;
  const suggestedAction = buildSuggestedAction(alert);
  const full = [demandTrend, timePrediction, confidenceText, suggestedAction]
    .filter(Boolean)
    .join(' ');

  return {
    summary: `${demandTrend} ${timePrediction}`.trim(),
    demandTrend,
    timePrediction,
    confidenceText,
    suggestedAction,
    full,
  };
}

function normalizeAlert(alert: PredictiveAlert | null | undefined): AlertWithReasoning | null {
  if (
    !alert ||
    typeof alert.id !== 'number' ||
    typeof alert.point_id !== 'number' ||
    typeof alert.resource_id !== 'number'
  ) {
    return null;
  }

  return {
    ...alert,
    rationale: alert.rationale ?? undefined,
    reasoning: buildReasoning(alert),
  };
}

export async function getAlerts(page: number, pageSize: number) {
  const response = await request<ApiResponse<PredictiveAlertsResponse>>(
    endpoints.alerts.list,
    {
      query: {
        page,
        pageSize,
      },
    },
  );

  const data = unwrapApiResponse(response);

  return {
    alerts: Array.isArray(data?.alerts)
      ? data.alerts
          .map((alert) =>
            normalizeAlert(alert as PredictiveAlert | null | undefined),
          )
          .filter((alert): alert is AlertWithReasoning => alert !== null)
      : [],
    total: typeof data?.total === 'number' ? data.total : 0,
  };
}

export async function dismissAlert(alertId: number) {
  try {
    await request<ApiResponse<null>>(endpoints.alerts.dismiss(alertId), {
      method: 'POST',
    });
  } catch (caught) {
    mapAlertsApiError(caught);
  }
}

export async function getProposal(proposalId: number) {
  const response = await request<ApiResponse<RebalancingProposal>>(
    endpoints.proposals.details(proposalId),
  );

  const proposal = unwrapApiResponse(response);
  if (!proposal) {
    throw new Error('Proposal response is empty');
  }

  return {
    ...proposal,
    transfers: Array.isArray(proposal?.transfers) ? proposal.transfers : [],
  };
}

export async function approveProposal(proposalId: number) {
  try {
    const response = await request<ApiResponse<RebalancingProposal>>(
      endpoints.proposals.approve(proposalId),
      {
        method: 'POST',
      },
    );

    const proposal = unwrapApiResponse(response);
    if (!proposal) {
      throw new Error('Proposal response is empty');
    }

    return {
      ...proposal,
      transfers: Array.isArray(proposal?.transfers) ? proposal.transfers : [],
    };
  } catch (caught) {
    mapAlertsApiError(caught);
  }
}

export async function rejectProposal(proposalId: number) {
  try {
    await request<ApiResponse<null>>(endpoints.proposals.dismiss(proposalId), {
      method: 'POST',
    });
  } catch (caught) {
    mapAlertsApiError(caught);
  }
}

export async function runAi() {
  await request<ApiResponse<{ status: string }>>(endpoints.ai.run, {
    method: 'POST',
  });
}

export type AlertWithProposal = AlertWithReasoning & {
  proposal?: RebalancingProposal | null;
};
