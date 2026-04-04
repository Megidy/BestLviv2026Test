import { useCallback, useEffect, useState } from 'react';

import { getMapPoints } from '@/features/map/api';
import type { MapPoint } from '@/shared/api';

type UseMapOptions = {
  autoRefreshMs?: number;
  enabled?: boolean;
};

export function useMap({
  autoRefreshMs = 30_000,
  enabled = true,
}: UseMapOptions = {}) {
  const [points, setPoints] = useState<MapPoint[]>([]);
  const [isLoading, setIsLoading] = useState(enabled);
  const [error, setError] = useState<string | null>(null);

  const loadPoints = useCallback(async () => {
    if (!enabled) {
      setPoints([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const response = await getMapPoints();
      setPoints(Array.isArray(response) ? response : []);
    } catch (caught) {
      setPoints([]);
      setError(caught instanceof Error ? caught.message : 'Failed to load map');
    } finally {
      setIsLoading(false);
    }
  }, [enabled]);

  useEffect(() => {
    void loadPoints();

    if (!enabled || autoRefreshMs <= 0) {
      return;
    }

    const interval = window.setInterval(() => {
      void loadPoints();
    }, autoRefreshMs);

    return () => window.clearInterval(interval);
  }, [autoRefreshMs, enabled, loadPoints]);

  return {
    points,
    isLoading,
    error,
    refetch: loadPoints,
  };
}
