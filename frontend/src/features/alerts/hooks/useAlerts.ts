import { useCallback, useEffect, useState } from 'react';

import {
  approveProposal,
  dismissAlert,
  getAlerts,
  getProposal,
  rejectProposal,
  runAi,
  type AlertWithReasoning,
} from '@/features/alerts/api/alertsApi';
import type { RebalancingProposal } from '@/shared/api';

type UseAlertsOptions = {
  page?: number;
  pageSize?: number;
  enabled?: boolean;
};

export function useAlerts({
  page = 1,
  pageSize = 20,
  enabled = true,
}: UseAlertsOptions = {}) {
  const [alerts, setAlerts] = useState<AlertWithReasoning[]>([]);
  const [proposals, setProposals] = useState<Record<number, RebalancingProposal | null>>(
    {},
  );
  const [isLoading, setIsLoading] = useState(enabled);
  const [isMutating, setIsMutating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [total, setTotal] = useState(0);

  const load = useCallback(async () => {
    if (!enabled) {
      setAlerts([]);
      setTotal(0);
      setError(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const response = await getAlerts(page, pageSize);
      setAlerts(Array.isArray(response.alerts) ? response.alerts : []);
      setTotal(typeof response.total === 'number' ? response.total : 0);
    } catch (caught) {
      setAlerts([]);
      setTotal(0);
      setError(caught instanceof Error ? caught.message : 'Failed to load alerts');
    } finally {
      setIsLoading(false);
    }
  }, [enabled, page, pageSize]);

  useEffect(() => {
    void load();
  }, [load]);

  const loadProposal = useCallback(async (proposalId: number) => {
    if (proposals[proposalId] !== undefined) {
      return proposals[proposalId];
    }

    try {
      const proposal = await getProposal(proposalId);
      setProposals((current) => ({
        ...current,
        [proposalId]: proposal,
      }));
      return proposal;
    } catch (caught) {
      setError(
        caught instanceof Error ? caught.message : 'Failed to load proposal',
      );
      throw caught;
    }
  }, [proposals]);

  const runMutation = useCallback(
    async (action: () => Promise<unknown>) => {
      setIsMutating(true);
      setError(null);

      try {
        await action();
        await load();
      } catch (caught) {
        setError(caught instanceof Error ? caught.message : 'Alert action failed');
        throw caught;
      } finally {
        setIsMutating(false);
      }
    },
    [load],
  );

  return {
    alerts,
    proposals,
    total,
    isLoading,
    isMutating,
    error,
    refetch: load,
    loadProposal,
    dismissAlert: (alertId: number) => runMutation(() => dismissAlert(alertId)),
    approveProposal: (proposalId: number) =>
      runMutation(async () => {
        const proposal = await approveProposal(proposalId);
        setProposals((current) => ({
          ...current,
          [proposalId]: proposal,
        }));
      }),
    dismissProposal: (proposalId: number) =>
      runMutation(async () => {
        await rejectProposal(proposalId);
        setProposals((current) => ({
          ...current,
          [proposalId]:
            current[proposalId] === null || current[proposalId] === undefined
              ? current[proposalId]
              : { ...current[proposalId], status: 'dismissed' },
        }));
      }),
    runAi: () => runMutation(() => runAi()),
  };
}
