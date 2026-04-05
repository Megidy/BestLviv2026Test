import { useCallback, useEffect, useState } from 'react';

import {
  AlertsConflictError,
  approveProposal,
  dismissAlert,
  getAlerts,
  getProposal,
  rejectProposal,
  runAi,
  type AlertWithReasoning,
} from '@/features/alerts/api/alertsApi';
import { invalidateCache } from '@/shared/api/apiClient';
import { endpoints } from '@/shared/api/endpoints';
import type { RebalancingProposal } from '@/shared/api';

type UseAlertsOptions = {
  page?: number;
  pageSize?: number;
  enabled?: boolean;
};

// Module-level cache so revisiting the alerts page shows data instantly
let _cachedAlerts: AlertWithReasoning[] | null = null;
let _cachedAlertTotal = 0;

export function useAlerts({
  page = 1,
  pageSize = 20,
  enabled = true,
}: UseAlertsOptions = {}) {
  const [alerts, setAlerts] = useState<AlertWithReasoning[]>(_cachedAlerts ?? []);
  const [proposals, setProposals] = useState<Record<number, RebalancingProposal | null>>(
    {},
  );
  const [isLoading, setIsLoading] = useState(enabled && _cachedAlerts === null);
  const [isMutating, setIsMutating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [total, setTotal] = useState(_cachedAlertTotal);
  const [pendingActionKeys, setPendingActionKeys] = useState<Record<string, boolean>>({});

  useEffect(() => {
    if (!notice) {
      return;
    }

    const timer = window.setTimeout(() => {
      setNotice(null);
    }, 2500);

    return () => window.clearTimeout(timer);
  }, [notice]);

  const load = useCallback(async () => {
    if (!enabled) {
      setAlerts([]);
      setTotal(0);
      setError(null);
      setNotice(null);
      setIsLoading(false);
      return;
    }

    if (_cachedAlerts === null) setIsLoading(true);
    setError(null);

    try {
      const response = await getAlerts(page, pageSize);
      const loadedAlerts = Array.isArray(response.alerts) ? response.alerts : [];
      _cachedAlerts = loadedAlerts;
      _cachedAlertTotal = typeof response.total === 'number' ? response.total : 0;
      setAlerts(loadedAlerts);
      setTotal(_cachedAlertTotal);

      // Eagerly fetch proposals for all alerts so action buttons reflect
      // current proposal status without requiring the user to expand first.
      const proposalIds = loadedAlerts
        .map((a) => a.proposal_id)
        .filter((id): id is number => id !== undefined && id !== null);

      if (proposalIds.length > 0) {
        const results = await Promise.allSettled(proposalIds.map((id) => getProposal(id)));
        const fresh: Record<number, RebalancingProposal | null> = {};
        results.forEach((result, i) => {
          fresh[proposalIds[i]] = result.status === 'fulfilled' ? result.value : null;
        });
        setProposals((current) => ({ ...current, ...fresh }));
      }
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
  }, []);

  const setActionPending = useCallback((actionKey: string, pending: boolean) => {
    setPendingActionKeys((current) => {
      if (pending) {
        if (current[actionKey]) {
          return current;
        }

        return {
          ...current,
          [actionKey]: true,
        };
      }

      if (!current[actionKey]) {
        return current;
      }

      const next = { ...current };
      delete next[actionKey];
      return next;
    });
  }, []);

  const runMutation = useCallback(
    async (
      actionKey: string,
      action: () => Promise<unknown>,
      options?: {
        optimisticUpdate?: () => void;
        rollback?: () => void;
        successMessage?: string;
      },
    ) => {
      if (pendingActionKeys[actionKey]) {
        return;
      }

      setError(null);
      setNotice(null);
      setIsMutating(true);
      setActionPending(actionKey, true);
      options?.optimisticUpdate?.();

      try {
        await action();
        if (options?.successMessage) {
          setNotice(options.successMessage);
        }
        // Bust HTTP GET cache so load() fetches fresh data (silently — no loading flash)
        invalidateCache(endpoints.alerts.list);
        invalidateCache('/v1/rebalancing-proposals');
        await load();
      } catch (caught) {
        if (caught instanceof AlertsConflictError) {
          options?.rollback?.();
          invalidateCache(endpoints.alerts.list);
          invalidateCache('/v1/rebalancing-proposals');
          await load();
          return;
        }

        options?.rollback?.();
        setError(caught instanceof Error ? caught.message : 'Alert action failed');
        throw caught;
      } finally {
        setActionPending(actionKey, false);
        setIsMutating(
          Object.keys(pendingActionKeys).filter((key) => key !== actionKey).length > 0,
        );
      }
    },
    [load, pendingActionKeys, setActionPending],
  );

  useEffect(() => {
    setIsMutating(Object.keys(pendingActionKeys).length > 0);
  }, [pendingActionKeys]);

  const markAlertResolved = useCallback((alertId: number) => {
    setAlerts((current) =>
      current.map((alert) =>
        alert.id === alertId ? { ...alert, status: 'resolved' } : alert,
      ),
    );
  }, []);

  const markProposalResolved = useCallback(
    (proposalId: number, status: 'approved' | 'dismissed') => {
      setAlerts((current) =>
        current.map((alert) =>
          alert.proposal_id === proposalId ? { ...alert, status: 'resolved' } : alert,
        ),
      );
      setProposals((current) => ({
        ...current,
        [proposalId]:
          current[proposalId] === null || current[proposalId] === undefined
            ? current[proposalId]
            : { ...current[proposalId], status },
      }));
    },
    [],
  );

  return {
    alerts,
    proposals,
    total,
    isLoading,
    isMutating,
    error,
    notice,
    pendingActionKeys,
    refetch: load,
    clearNotice: () => setNotice(null),
    loadProposal,
    dismissAlert: (alertId: number) =>
      runMutation(`dismiss-alert:${alertId}`, () => dismissAlert(alertId), {
        optimisticUpdate: () => markAlertResolved(alertId),
        rollback: () => void load(),
        successMessage: 'Alert resolved.',
      }),
    approveProposal: (proposalId: number) =>
      runMutation(`approve-proposal:${proposalId}`, async () => {
        const proposal = await approveProposal(proposalId);
        setProposals((current) => ({
          ...current,
          [proposalId]: proposal,
        }));
      }, {
        optimisticUpdate: () => markProposalResolved(proposalId, 'approved'),
        rollback: () => void load(),
        successMessage: 'Proposal approved.',
      }),
    dismissProposal: (proposalId: number) =>
      runMutation(`dismiss-proposal:${proposalId}`, async () => {
        await rejectProposal(proposalId);
      }, {
        optimisticUpdate: () => markProposalResolved(proposalId, 'dismissed'),
        rollback: () => void load(),
        successMessage: 'Proposal rejected.',
      }),
    runAi: () =>
      runMutation('run-ai', () => runAi(), {
        successMessage: 'Prediction run started.',
      }),
  };
}
