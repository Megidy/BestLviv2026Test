import { useCallback, useEffect, useRef, useState } from 'react';

import { getNearestStock } from '@/features/map/api';
import type { NearestStockResult } from '@/shared/api';

type UseNearestStockOptions = {
  resourceId?: number;
  customerId?: number;
  needed?: number;
  debounceMs?: number;
  enabled?: boolean;
};

function getValidNearestStockParams(
  resourceId?: number,
  customerId?: number,
  needed?: number,
) {
  const normalizedResourceId = Number(resourceId);
  const normalizedCustomerId = Number(customerId);
  const normalizedNeeded = Number(needed);

  if (
    !Number.isFinite(normalizedResourceId) ||
    !Number.isFinite(normalizedCustomerId) ||
    !Number.isFinite(normalizedNeeded) ||
    normalizedResourceId <= 0 ||
    normalizedCustomerId <= 0 ||
    normalizedNeeded <= 0
  ) {
    return null;
  }

  return {
    resourceId: normalizedResourceId,
    customerId: normalizedCustomerId,
    needed: normalizedNeeded,
  };
}

export function useNearestStock({
  resourceId,
  customerId,
  needed,
  debounceMs = 400,
  enabled = true,
}: UseNearestStockOptions = {}) {
  const [data, setData] = useState<NearestStockResult[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const requestIdRef = useRef(0);

  const clearResults = useCallback(() => {
    requestIdRef.current += 1;
    setData([]);
    setIsLoading(false);
    setError(null);
  }, []);

  const load = useCallback(async () => {
    const requestParams = enabled
      ? getValidNearestStockParams(resourceId, customerId, needed)
      : null;

    if (!requestParams) {
      console.debug('[nearest-stock] request blocked', {
        enabled,
        resourceId,
        customerId,
        needed,
      });
      clearResults();
      return [];
    }

    const requestId = requestIdRef.current;

    try {
      const response = await getNearestStock(requestParams);

      if (requestId !== requestIdRef.current) {
        return [];
      }

      const nextData = Array.isArray(response) ? response : [];
      setData(nextData);
      return nextData;
    } catch (caught) {
      if (requestId !== requestIdRef.current) {
        return [];
      }

      setData([]);
      setError('No data available');
      return [];
    } finally {
      if (requestId === requestIdRef.current) {
        setIsLoading(false);
      }
    }
  }, [clearResults, customerId, enabled, needed, resourceId]);

  useEffect(() => {
    if (!enabled || !getValidNearestStockParams(resourceId, customerId, needed)) {
      clearResults();
      return;
    }

    const requestId = ++requestIdRef.current;
    setData([]);
    setError(null);
    setIsLoading(true);

    const timer = window.setTimeout(() => {
      void load();
    }, debounceMs);

    return () => {
      window.clearTimeout(timer);

      if (requestIdRef.current === requestId) {
        requestIdRef.current += 1;
        setIsLoading(false);
      }
    };
  }, [clearResults, customerId, debounceMs, enabled, load, needed, resourceId]);

  return {
    data,
    isLoading,
    error,
    refetch: load,
    clear: clearResults,
  };
}
