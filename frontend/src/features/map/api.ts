import {
  endpoints,
  request,
  unwrapApiResponse,
  type ApiResponse,
  type MapPoint,
  type NearestStockResult,
} from '@/shared/api';

function normalizeMapPoint(point: MapPoint | null | undefined): MapPoint | null {
  if (
    !point ||
    typeof point.id !== 'number' ||
    typeof point.name !== 'string' ||
    typeof point.lat !== 'number' ||
    typeof point.lng !== 'number'
  ) {
    return null;
  }

  return {
    ...point,
    type: point.type === 'warehouse' ? 'warehouse' : 'customer',
    status:
      point.status === 'normal' ||
      point.status === 'elevated' ||
      point.status === 'critical' ||
      point.status === 'predictive'
        ? point.status
        : 'normal',
    alert_count: typeof point.alert_count === 'number' ? point.alert_count : 0,
  };
}

function normalizeNearestStockResult(
  entry: NearestStockResult | null | undefined,
): NearestStockResult | null {
  if (
    !entry ||
    typeof entry.warehouse_id !== 'number' ||
    typeof entry.warehouse_name !== 'string'
  ) {
    return null;
  }

  return {
    warehouse_id: entry.warehouse_id,
    warehouse_name: entry.warehouse_name,
    surplus: typeof entry.surplus === 'number' ? entry.surplus : 0,
    distance_km: typeof entry.distance_km === 'number' ? entry.distance_km : 0,
    estimated_arrival_hours:
      typeof entry.estimated_arrival_hours === 'number'
        ? entry.estimated_arrival_hours
        : 0,
    score: typeof entry.score === 'number' ? entry.score : 0,
  };
}

export async function getMapPoints() {
  const response = await request<unknown>(endpoints.map.points);

  if (!Array.isArray(response)) {
    return [];
  }

  return response
    .map((entry) => normalizeMapPoint(entry as MapPoint | null | undefined))
    .filter((entry): entry is MapPoint => entry !== null);
}

export async function getNearestStock(params: {
  resourceId: number;
  customerId: number;
  needed?: number;
}) {
  // Diagnosis: the 400 was caused by a contract mismatch in this request builder.
  // The frontend sent `customer_id` + `needed`, but the current backend handler
  // for `/v1/stock/nearest` validates `point_id` and reads `quantity`.
  // Fix: keep the same validated numeric values, but send the field names the
  // backend actually binds today.
  const resource_id = Number(params.resourceId);
  const customer_id = Number(params.customerId);
  const needed = Number(params.needed);

  if (
    !Number.isFinite(resource_id) ||
    !Number.isFinite(customer_id) ||
    !Number.isFinite(needed) ||
    resource_id <= 0 ||
    customer_id <= 0 ||
    needed <= 0
  ) {
    console.debug('[nearest-stock] skipped invalid params', {
      resource_id,
      customer_id,
      needed,
    });
    return [];
  }

  console.debug('[nearest-stock] request params', {
    resource_id,
    customer_id,
    needed,
  });

  const response = await request<ApiResponse<NearestStockResult[]>>(
    endpoints.stock.nearest,
    {
      query: {
        resource_id,
        point_id: customer_id,
        quantity: needed,
      },
    },
  );

  const data = unwrapApiResponse(response);

  if (!Array.isArray(data)) {
    return [];
  }

  return data
    .map((entry) =>
      normalizeNearestStockResult(entry as NearestStockResult | null | undefined),
    )
    .filter((entry): entry is NearestStockResult => entry !== null);
}
