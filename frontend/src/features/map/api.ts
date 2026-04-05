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
  const response = await request<ApiResponse<NearestStockResult[]>>(
    endpoints.stock.nearest,
    {
      query: {
        resource_id: params.resourceId,
        customer_id: params.customerId,
        point_id: params.customerId,
        needed: params.needed,
        quantity: params.needed,
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
