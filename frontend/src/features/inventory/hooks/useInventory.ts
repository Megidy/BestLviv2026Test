import { useCallback, useEffect, useState } from 'react';

import {
  getInventory,
  type InventoryQuery,
  type InventoryRecord,
} from '@/features/inventory/api/inventoryApi';

type UseInventoryOptions = InventoryQuery & {
  enabled?: boolean;
};

type InventoryCacheEntry = { items: InventoryRecord[]; total: number };

// Module-level keyed cache so revisiting a page shows data instantly
const _inventoryCache = new Map<string, InventoryCacheEntry>();

function buildCacheKey(q: InventoryQuery): string {
  return `${q.locationId}|${q.page}|${q.pageSize}|${q.category ?? ''}|${q.resourceName ?? ''}`;
}

export function useInventory({
  enabled = true,
  ...query
}: UseInventoryOptions) {
  const cacheKey = buildCacheKey(query);
  const cached = _inventoryCache.get(cacheKey);

  const [items, setItems] = useState<InventoryRecord[]>(cached?.items ?? []);
  const [total, setTotal] = useState(cached?.total ?? 0);
  const [isLoading, setIsLoading] = useState(enabled && !cached);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!enabled) {
      setItems([]);
      setTotal(0);
      setError(null);
      setIsLoading(false);
      return;
    }

    const key = buildCacheKey(query);
    if (!_inventoryCache.has(key)) setIsLoading(true);
    setError(null);

    try {
      const response = await getInventory(query);
      const entry: InventoryCacheEntry = {
        items: Array.isArray(response.items) ? response.items : [],
        total: typeof response.total === 'number' ? response.total : 0,
      };
      _inventoryCache.set(key, entry);
      setItems(entry.items);
      setTotal(entry.total);
    } catch (caught) {
      const stale = _inventoryCache.get(key);
      if (stale) {
        setItems(stale.items);
        setTotal(stale.total);
      } else {
        setItems([]);
        setTotal(0);
      }
      setError(
        caught instanceof Error ? caught.message : 'Failed to load inventory',
      );
    } finally {
      setIsLoading(false);
    }
  }, [
    enabled,
    query.category,
    query.locationId,
    query.page,
    query.pageSize,
    query.resourceName,
  ]);

  useEffect(() => {
    void load();
  }, [load]);

  return {
    items,
    total,
    isLoading,
    error,
    refetch: load,
  };
}
