import {
  endpoints,
  request,
  unwrapApiResponse,
  type Allocation,
  type AllocationsResponse,
  type ApiResponse,
  type DemandReading,
  type DemandReadingsResponse,
  type DeliveryPriority,
  type DeliveryRequest,
  type DeliveryRequestsResponse,
} from '@/shared/api';

export type DeliveryRequestPayload = {
  destination_id: number;
  priority: DeliveryPriority;
  arrive_till?: string;
  items: Array<{
    resource_id: number;
    quantity: number;
  }>;
};

function normalizeDeliveryRequest(
  request: DeliveryRequest | null | undefined,
): DeliveryRequest {
  return {
    ...(request ?? {}),
    items: Array.isArray(request?.items) ? request.items : [],
    allocations: Array.isArray(request?.allocations) ? request.allocations : [],
  } as DeliveryRequest;
}

export async function listRequests(params: {
  page: number;
  pageSize: number;
  status?: string;
  priority?: string;
}) {
  const response = await request<ApiResponse<DeliveryRequestsResponse>>(
    endpoints.requests.list,
    {
      query: params,
    },
  );

  const data = unwrapApiResponse(response);

  return {
    requests: Array.isArray(data?.requests)
      ? data.requests.map(normalizeDeliveryRequest)
      : [],
    total: typeof data?.total === 'number' ? data.total : 0,
  };
}

export async function getRequestDetails(requestId: number) {
  const response = await request<ApiResponse<DeliveryRequest>>(
    endpoints.requests.details(requestId),
  );

  return normalizeDeliveryRequest(unwrapApiResponse(response));
}

export async function createRequest(payload: DeliveryRequestPayload) {
  const response = await request<ApiResponse<DeliveryRequest>>(
    endpoints.requests.create,
    {
      method: 'POST',
      body: payload,
    },
  );

  return normalizeDeliveryRequest(unwrapApiResponse(response));
}

export async function allocatePendingRequests() {
  const response = await request<ApiResponse<{ allocated: number }>>(
    endpoints.requests.allocate,
    {
      method: 'POST',
    },
  );

  const data = unwrapApiResponse(response);

  return {
    allocated: typeof data?.allocated === 'number' ? data.allocated : 0,
  };
}

export async function updateRequestItemQuantity(
  requestId: number,
  resourceId: number,
  quantity: number,
) {
  await request<ApiResponse<null>>(endpoints.requests.updateItems(requestId), {
    method: 'PATCH',
    body: {
      resource_id: resourceId,
      quantity,
    },
  });
}

export async function escalateRequest(requestId: number) {
  const response = await request<ApiResponse<DeliveryRequest>>(
    endpoints.requests.escalate(requestId),
    {
      method: 'POST',
    },
  );

  return normalizeDeliveryRequest(unwrapApiResponse(response));
}

export async function deliverRequest(requestId: number) {
  await request<ApiResponse<null>>(endpoints.requests.deliver(requestId), {
    method: 'POST',
  });
}

export async function listAllocations(params: {
  page: number;
  pageSize: number;
  request_id?: number;
  status?: string;
}) {
  const response = await request<ApiResponse<AllocationsResponse>>(
    endpoints.allocations.list,
    {
      query: params,
    },
  );

  const data = unwrapApiResponse(response);

  return {
    allocations: Array.isArray(data?.allocations) ? data.allocations : [],
    total: typeof data?.total === 'number' ? data.total : 0,
  };
}

export async function approveAllocation(allocationId: number) {
  const response = await request<ApiResponse<Allocation>>(
    endpoints.allocations.approve(allocationId),
    {
      method: 'POST',
    },
  );

  return unwrapApiResponse(response);
}

export async function dispatchAllocation(allocationId: number) {
  const response = await request<ApiResponse<Allocation>>(
    endpoints.allocations.dispatch(allocationId),
    {
      method: 'POST',
    },
  );

  return unwrapApiResponse(response);
}

export async function recordDemand(payload: {
  point_id: number;
  resource_id: number;
  quantity: number;
  source?: 'manual' | 'sensor' | 'predicted';
  recorded_at?: string;
}) {
  const response = await request<ApiResponse<DemandReading>>(endpoints.demand.create, {
    method: 'POST',
    body: payload,
  });

  return unwrapApiResponse(response);
}

export async function getDemandReadings(
  pointId: number,
  page: number,
  pageSize: number,
) {
  const response = await request<ApiResponse<DemandReadingsResponse>>(
    endpoints.demand.byPoint(pointId),
    {
      query: {
        page,
        pageSize,
      },
    },
  );

  const data = unwrapApiResponse(response);

  return {
    readings: Array.isArray(data?.readings) ? data.readings : [],
    total: typeof data?.total === 'number' ? data.total : 0,
  };
}
