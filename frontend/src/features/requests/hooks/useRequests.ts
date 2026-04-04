import { useCallback, useEffect, useState } from 'react';

import {
  allocatePendingRequests,
  approveAllocation,
  createRequest,
  deliverRequest,
  dispatchAllocation,
  escalateRequest,
  getDemandReadings,
  getRequestDetails,
  listRequests,
  recordDemand,
  updateRequestItemQuantity,
  type DeliveryRequestPayload,
} from '@/features/requests/api/requestsApi';
import type {
  DemandReading,
  DeliveryPriority,
  DeliveryRequest,
  DeliveryStatus,
} from '@/shared/api';

type UseRequestsOptions = {
  page?: number;
  pageSize?: number;
  priority?: DeliveryPriority | '';
  status?: DeliveryStatus | '';
  resourceId?: number;
  pointId?: number;
  demandPageSize?: number;
  enabled?: boolean;
};

export function useRequests({
  page = 1,
  pageSize = 20,
  priority = '',
  status = '',
  resourceId,
  pointId,
  demandPageSize = 12,
  enabled = true,
}: UseRequestsOptions = {}) {
  const [requests, setRequests] = useState<DeliveryRequest[]>([]);
  const [total, setTotal] = useState(0);
  const [demandReadings, setDemandReadings] = useState<DemandReading[]>([]);
  const [isLoading, setIsLoading] = useState(enabled);
  const [isMutating, setIsMutating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!enabled) {
      setRequests([]);
      setTotal(0);
      setError(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const response = await listRequests({
        page,
        pageSize,
        priority,
        status,
      });

      const detailedRequests = await Promise.all(
        (response.requests ?? []).map((requestItem) =>
          getRequestDetails(requestItem.id),
        ),
      );

      const filteredRequests = resourceId
        ? detailedRequests.filter(
            (requestItem) =>
              requestItem.resource_id === resourceId ||
              requestItem.items?.some((item) => item.resource_id === resourceId),
          )
        : detailedRequests;

      setRequests(filteredRequests);
      setTotal(resourceId ? filteredRequests.length : response.total);
    } catch (caught) {
      setRequests([]);
      setTotal(0);
      setError(
        caught instanceof Error ? caught.message : 'Failed to load requests',
      );
    } finally {
      setIsLoading(false);
    }
  }, [enabled, page, pageSize, priority, resourceId, status]);

  const loadDemand = useCallback(async () => {
    if (!enabled || !pointId) {
      setDemandReadings([]);
      return;
    }

    try {
      const response = await getDemandReadings(pointId, 1, demandPageSize);
      setDemandReadings(Array.isArray(response.readings) ? response.readings : []);
    } catch (caught) {
      setDemandReadings([]);
      setError(
        caught instanceof Error
          ? caught.message
          : 'Failed to load demand readings',
      );
    }
  }, [demandPageSize, enabled, pointId]);

  useEffect(() => {
    void load();
  }, [load]);

  useEffect(() => {
    void loadDemand();
  }, [loadDemand]);

  const runMutation = useCallback(
    async (action: () => Promise<unknown>) => {
      setIsMutating(true);
      setError(null);

      try {
        await action();
        await Promise.all([load(), loadDemand()]);
      } catch (caught) {
        setError(
          caught instanceof Error ? caught.message : 'Request action failed',
        );
        throw caught;
      } finally {
        setIsMutating(false);
      }
    },
    [load, loadDemand],
  );

  return {
    requests,
    total,
    demandReadings,
    isLoading,
    isMutating,
    error,
    refetch: load,
    createRequest: (payload: DeliveryRequestPayload) =>
      runMutation(() => createRequest(payload)),
    allocatePending: () => runMutation(() => allocatePendingRequests()),
    updateQuantity: (requestId: number, targetResourceId: number, quantity: number) =>
      runMutation(() =>
        updateRequestItemQuantity(requestId, targetResourceId, quantity),
      ),
    escalate: (requestId: number) => runMutation(() => escalateRequest(requestId)),
    approveAllocation: (allocationId: number) =>
      runMutation(() => approveAllocation(allocationId)),
    dispatchAllocation: (allocationId: number) =>
      runMutation(() => dispatchAllocation(allocationId)),
    deliver: (requestId: number) => runMutation(() => deliverRequest(requestId)),
    recordDemand: (payload: Parameters<typeof recordDemand>[0]) =>
      runMutation(() => recordDemand(payload)),
  };
}
