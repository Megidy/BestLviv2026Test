import {
  endpoints,
  request,
  unwrapApiResponse,
  type ApiResponse,
  type PredictiveAlertsResponse,
  type PredictiveAlert,
  type RebalancingProposal,
} from '@/shared/api';

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
    alerts: Array.isArray(data?.alerts) ? data.alerts : [],
    total: typeof data?.total === 'number' ? data.total : 0,
  };
}

export async function dismissAlert(alertId: number) {
  await request<ApiResponse<null>>(endpoints.alerts.dismiss(alertId), {
    method: 'POST',
  });
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
}

export async function rejectProposal(proposalId: number) {
  await request<ApiResponse<null>>(endpoints.proposals.dismiss(proposalId), {
    method: 'POST',
  });
}

export async function runAi() {
  await request<ApiResponse<{ status: string }>>(endpoints.ai.run, {
    method: 'POST',
  });
}

export type AlertWithProposal = PredictiveAlert & {
  proposal?: RebalancingProposal | null;
};
