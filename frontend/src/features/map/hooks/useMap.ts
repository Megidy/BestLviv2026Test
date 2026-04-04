import { useCallback, useEffect, useState } from 'react';

import { getMapPoints, getNearestStock } from '@/features/map/api/mapApi';
import type { MapPoint, NearestStockResult } from '@/shared/api';

type UseMapOptions = {
  resourceId?: number;
  pointId?: number;
  needed?: number;
  autoRefreshMs?: number;
  enabled?: boolean;
};

export function useMap({
  resourceId,
  pointId,
  needed,
  autoRefreshMs = 30_000,
  enabled = true,
}: UseMapOptions = {}) {
  const [points, setPoints] = useState<MapPoint[]>([]);
  const [nearestStock, setNearestStock] = useState<NearestStockResult[]>([]);
  const [isLoading, setIsLoading] = useState(enabled);
  const [isNearestStockLoading, setIsNearestStockLoading] = useState(false);
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
      setError(caught instanceof Error ? caught.message : 'Failed to load map');
    } finally {
      setIsLoading(false);
    }
  }, [enabled]);

  const loadNearestStock = useCallback(async () => {
    if (!enabled || !resourceId || !pointId) {
      setNearestStock([]);
      setIsNearestStockLoading(false);
      return;
    }

    setIsNearestStockLoading(true);
    setError(null);

    try {
      const response = await getNearestStock(resourceId, pointId, needed);
      setNearestStock(Array.isArray(response) ? response : []);
    } catch (caught) {
      setError(
        caught instanceof Error ? caught.message : 'Failed to load nearest stock',
      );
    } finally {
      setIsNearestStockLoading(false);
    }
  }, [enabled, needed, pointId, resourceId]);

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

  useEffect(() => {
    void loadNearestStock();
  }, [loadNearestStock]);

  return {
    points,
    nearestStock,
    isLoading,
    isNearestStockLoading,
    error,
    refetch: loadPoints,
    refetchNearestStock: loadNearestStock,
  };
}
