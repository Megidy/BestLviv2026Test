import {
  endpoints,
  request,
  unwrapApiResponse,
  type ApiResponse,
  type InventoryResponse,
} from '@/shared/api';

export type InventoryRecord = {
  inventoryId: number;
  resourceId: number;
  name: string;
  category: string;
  unit: string;
  quantity: number;
  safetyStock: number;
  allocatableQuantity: number;
  updatedAt: string;
  locationId: number;
  logoUri: string;
};

export type InventoryQuery = {
  locationId: number;
  resourceName?: string;
  category?: string;
  page: number;
  pageSize: number;
};

export async function getInventory({
  locationId,
  resourceName,
  category,
  page,
  pageSize,
}: InventoryQuery) {
  const response = await request<ApiResponse<InventoryResponse>>(
    endpoints.inventory.byLocation(locationId),
    {
      query: {
        resource_name: resourceName,
        resource_category: category && category !== 'all' ? category : undefined,
        page,
        pageSize,
      },
    },
  );

  const data = unwrapApiResponse(response);
  const inventoryUnits = Array.isArray(data?.inventory_units)
    ? data.inventory_units
    : [];
  const total = typeof data?.total === 'number' ? data.total : 0;

  return {
    items: inventoryUnits
      .filter(
        (unit): unit is NonNullable<typeof unit> =>
          Boolean(unit?.inventory && unit.resource),
      )
      .map<InventoryRecord>(({ inventory, resource }) => {
        const quantity =
          typeof inventory.quantity === 'number' ? inventory.quantity : 0;
        const safetyStock = quantity * 0.2;

        return {
          inventoryId: inventory.id,
          resourceId: resource.resource,
          name: resource.name ?? `Resource #${resource.resource}`,
          category: resource.category ?? 'Uncategorized',
          unit: resource.unit_measure ?? 'units',
          quantity,
          safetyStock,
          allocatableQuantity: Math.max(quantity - safetyStock, 0),
          updatedAt: inventory.updated_at ?? '',
          locationId: inventory.location_id,
          logoUri: resource.logo_uri ?? '',
        };
      }),
    total,
  };
}
