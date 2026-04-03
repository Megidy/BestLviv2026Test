import { apiClient } from '.';

export type MapPointStatus = 'normal' | 'elevated' | 'critical' | 'predictive';
export type MapPointType = 'warehouse' | 'customer';

export interface MapPoint {
  id: number;
  name: string;
  type: MapPointType;
  lat: number;
  lng: number;
  status: MapPointStatus;
  alert_count: number;
}

export function getMapPoints(): Promise<MapPoint[]> {
  return apiClient<MapPoint[]>('/map/points');
}
