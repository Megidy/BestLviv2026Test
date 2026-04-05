import { useCallback, useEffect, useState } from 'react';

import { getMapPoints } from '@/features/map/api';
import type { MapPoint } from '@/shared/api';

type UseMapOptions = {
  autoRefreshMs?: number;
  enabled?: boolean;
};

// Module-level cache so revisiting a page shows data instantly
let _cachedPoints: MapPoint[] | null = null;

export function useMap({
  autoRefreshMs = 30_000,
  enabled = true,
}: UseMapOptions = {}) {
  const [points, setPoints] = useState<MapPoint[]>(_cachedPoints ?? []);
  const [isLoading, setIsLoading] = useState(enabled && _cachedPoints === null);
  const [error, setError] = useState<string | null>(null);

  const loadPoints = useCallback(async () => {
    if (!enabled) {
      setPoints([]);
      setIsLoading(false);
      return;
    }

    if (_cachedPoints === null) setIsLoading(true);
    setError(null);

    try {
      const response = await getMapPoints();
      _cachedPoints = response;
      setPoints(response);
    } catch (caught) {
      // Keep showing cached data on error instead of blanking out
      if (_cachedPoints !== null) setPoints(_cachedPoints);
      else setPoints([]);
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
