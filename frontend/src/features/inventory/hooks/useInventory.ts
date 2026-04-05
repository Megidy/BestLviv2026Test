import { useCallback, useEffect, useState } from 'react';

import {
  getInventory,
  type InventoryQuery,
  type InventoryRecord,
} from '@/features/inventory/api/inventoryApi';

type UseInventoryOptions = InventoryQuery & {
  enabled?: boolean;
};

export function useInventory({
  enabled = true,
  ...query
}: UseInventoryOptions) {
  const [items, setItems] = useState<InventoryRecord[]>([]);
  const [total, setTotal] = useState(0);
  const [isLoading, setIsLoading] = useState(enabled);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!enabled) {
      setItems([]);
      setTotal(0);
      setError(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const response = await getInventory(query);
      setItems(Array.isArray(response.items) ? response.items : []);
      setTotal(typeof response.total === 'number' ? response.total : 0);
    } catch (caught) {
      setItems([]);
      setTotal(0);
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
