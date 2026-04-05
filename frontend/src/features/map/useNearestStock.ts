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
    setData([]);
    setIsLoading(false);
    setError(null);
  }, []);

  const load = useCallback(async () => {
    if (!enabled || !resourceId || !customerId || !needed || needed <= 0) {
      clearResults();
      return [];
    }

    const requestId = ++requestIdRef.current;
    setIsLoading(true);
    setError(null);

    try {
      const response = await getNearestStock({
        resourceId,
        customerId,
        needed,
      });

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
      setError(
        caught instanceof Error ? caught.message : 'Failed to load nearest stock',
      );
      return [];
    } finally {
      if (requestId === requestIdRef.current) {
        setIsLoading(false);
      }
    }
  }, [clearResults, customerId, enabled, needed, resourceId]);

  useEffect(() => {
    if (!enabled || !resourceId || !customerId || !needed || needed <= 0) {
      clearResults();
      return;
    }

    const timer = window.setTimeout(() => {
      void load();
    }, debounceMs);

    return () => window.clearTimeout(timer);
  }, [clearResults, customerId, debounceMs, enabled, load, needed, resourceId]);

  return {
    data,
    isLoading,
    error,
    refetch: load,
  };
}
