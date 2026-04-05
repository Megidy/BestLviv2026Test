export type ApiMetadata = {
  error?: string;
  message?: string;
  status_code?: number;
  timestamp?: string;
};

export type ApiResponse<T> = {
  data: T;
  metadata: ApiMetadata;
};

export type UserRole = 'worker' | 'dispatcher' | 'admin';
export type DeliveryPriority = 'normal' | 'elevated' | 'critical' | 'urgent';
export type DeliveryStatus =
  | 'pending'
  | 'allocated'
  | 'in_transit'
  | 'delivered'
  | 'cancelled';
export type AllocationStatus =
  | 'planned'
  | 'approved'
  | 'in_transit'
  | 'delivered'
  | 'cancelled';
export type AlertStatus = 'open' | 'dismissed' | 'resolved';
export type ProposalStatus = 'pending' | 'approved' | 'dismissed';
export type DemandSource = 'manual' | 'sensor' | 'predicted';
export type MapPointStatus = 'normal' | 'elevated' | 'critical' | 'predictive';
export type MapPointType = 'warehouse' | 'customer';

export type User = {
  id: number;
  username: string;
  role: UserRole;
  location_id: number;
  created_at: string;
  updated_at: string;
};

export type Inventory = {
  id: number;
  location_id: number;
  resource_id: number;
  quantity: number;
  created_at: string;
  updated_at: string;
};

export type Resource = {
  resource: number;
  name: string;
  category: string;
  unit_measure: string;
  logo_uri: string;
  created_at: string;
  updated_at: string;
};

export type InventoryUnit = {
  inventory: Inventory;
  resource: Resource;
};

export type InventoryResponse = {
  inventory_units: InventoryUnit[];
  total: number;
};

export type DeliveryRequestItem = {
  id: number;
  request_id: number;
  resource_id: number;
  quantity: number;
  created_at: string;
  updated_at: string;
};

export type Allocation = {
  id: number;
  request_id: number;
  source_warehouse_id: number;
  resource_id: number;
  quantity: number;
  status: AllocationStatus;
  created_at: string;
  updated_at: string;
  dispatched_at?: string;
};

export type DeliveryRequest = {
  id: number;
  destination_id: number;
  resource_id: number;
  user_id: number;
  quantity: number;
  priority: DeliveryPriority;
  status: DeliveryStatus;
  arrive_till?: string;
  created_at: string;
  updated_at: string;
  items?: DeliveryRequestItem[];
  allocations?: Allocation[];
};

export type DeliveryRequestsResponse = {
  requests: DeliveryRequest[];
  total: number;
};

export type AllocationsResponse = {
  allocations: Allocation[];
  total: number;
};

export type DemandReading = {
  id: number;
  point_id: number;
  resource_id: number;
  quantity: number;
  source: DemandSource;
  recorded_at: string;
  created_at: string;
};

export type DemandReadingsResponse = {
  readings: DemandReading[];
  total: number;
};

export type PredictiveAlert = {
  id: number;
  point_id: number;
  resource_id: number;
  predicted_shortfall_at: string;
  confidence: number;
  status: AlertStatus;
  proposal_id?: number;
  rationale?: string;
  created_at: string;
  updated_at: string;
};

export type PredictiveAlertsResponse = {
  alerts: PredictiveAlert[];
  total: number;
};

export type RebalancingTransfer = {
  id: number;
  proposal_id: number;
  from_warehouse_id: number;
  quantity: number;
  estimated_arrival_hours: number;
  created_at: string;
};

export type RebalancingProposal = {
  id: number;
  target_point_id: number;
  resource_id: number;
  urgency: string;
  confidence: number;
  status: ProposalStatus;
  transfers?: RebalancingTransfer[];
  created_at: string;
  updated_at: string;
};

export type NearestStockResult = {
  warehouse_id: number;
  warehouse_name: string;
  surplus: number;
  distance_km: number;
  estimated_arrival_hours: number;
  score: number;
};

export type MapPoint = {
  id: number;
  name: string;
  type: MapPointType;
  lat: number;
  lng: number;
  status: MapPointStatus;
  alert_count: number;
};

export type AuditEntry = {
  id: number;
  actor_id?: number;
  actor_role: string;
  action: string;
  entity_type?: string;
  entity_id?: number;
  before_value?: string;
  after_value?: string;
  ip_address?: string;
  created_at: string;
};

export type AuditLogResponse = {
  entries: AuditEntry[];
  total: number;
};
