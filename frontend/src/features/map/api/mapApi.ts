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

export async function getMapPoints() {
  const response = await request<unknown>(endpoints.map.points);

  if (!Array.isArray(response)) {
    return [];
  }

  return response
    .map((entry) => normalizeMapPoint(entry as MapPoint | null | undefined))
    .filter((entry): entry is MapPoint => entry !== null);
}

export async function getNearestStock(
  resourceId: number,
  pointId: number,
  quantity?: number,
) {
  const response = await request<ApiResponse<NearestStockResult[]>>(
    endpoints.stock.nearest,
    {
      query: {
        resource_id: resourceId,
        point_id: pointId,
        quantity,
      },
    },
  );

  const data = unwrapApiResponse(response);

  if (!Array.isArray(data)) {
    return [];
  }

  return data.filter(
    (entry): entry is NearestStockResult =>
      Boolean(
        entry &&
          typeof entry.warehouse_id === 'number' &&
          typeof entry.warehouse_name === 'string',
      ),
  );
}
