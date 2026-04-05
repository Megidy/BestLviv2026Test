export const API_BASE_URL =
  'https://ec2-56-228-1-130.eu-north-1.compute.amazonaws.com:8080';

export const endpoints = {
  auth: {
    login: '/v1/auth/login',
    me: '/v1/auth/me',
  },
  inventory: {
    byLocation: (locationId: number) => `/v1/inventory/${locationId}`,
  },
  requests: {
    list: '/v1/delivery-requests',
    create: '/v1/delivery-requests',
    allocate: '/v1/delivery-requests/allocate',
    details: (id: number) => `/v1/delivery-requests/${id}`,
    deliver: (id: number) => `/v1/delivery-requests/${id}/deliver`,
    escalate: (id: number) => `/v1/delivery-requests/${id}/escalate`,
    updateItems: (id: number) => `/v1/delivery-requests/${id}/items`,
  },
  allocations: {
    list: '/v1/allocations',
    approve: (id: number) => `/v1/allocations/${id}/approve`,
    dispatch: (id: number) => `/v1/allocations/${id}/dispatch`,
  },
  alerts: {
    list: '/v1/predictive-alerts',
    dismiss: (id: number) => `/v1/predictive-alerts/${id}/dismiss`,
  },
  proposals: {
    details: (id: number) => `/v1/rebalancing-proposals/${id}`,
    approve: (id: number) => `/v1/rebalancing-proposals/${id}/approve`,
    dismiss: (id: number) => `/v1/rebalancing-proposals/${id}/dismiss`,
  },
  ai: {
    run: '/v1/ai/run',
  },
  demand: {
    create: '/v1/demand-readings',
    byPoint: (pointId: number) => `/v1/demand-readings/${pointId}`,
  },
  stock: {
    nearest: '/v1/stock/nearest',
  },
  map: {
    points: '/v1/map/points',
  },
  audit: {
    list: '/v1/audit-log',
  },
} as const;
