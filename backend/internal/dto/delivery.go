package dto

import "github.com/Megidy/BestLviv2026Test/internal/entity"

// --- Delivery Request ---

type DeliveryRequestFilter struct {
	Status   entity.DeliveryStatus   `query:"status"`
	Priority entity.DeliveryPriority `query:"priority"`
	UserID   uint                    `query:"user_id"`
	Limit    int
	Offset   int
}

type GetDeliveryRequestsResponse struct {
	Requests []entity.DeliveryRequest `json:"requests"`
	Total    int                      `json:"total"`
}

// --- Allocation ---

type AllocationFilter struct {
	Status    entity.AllocationStatus `query:"status"`
	RequestID uint                    `query:"request_id"`
	Limit     int
	Offset    int
}

type GetAllocationsResponse struct {
	Allocations []entity.Allocation `json:"allocations"`
	Total       int                 `json:"total"`
}

// --- Nearest Stock ---

type NearestStockResult struct {
	WarehouseID           uint    `json:"warehouse_id"`
	WarehouseName         string  `json:"warehouse_name"`
	Surplus               float64 `json:"surplus"`
	DistanceKm            float64 `json:"distance_km"`
	EstimatedArrivalHours float64 `json:"estimated_arrival_hours"`
	Score                 float64 `json:"score"`
}

// --- Audit Log ---

type AuditFilter struct {
	ActorID    uint               `query:"actor_id"`
	Action     entity.AuditAction `query:"action"`
	EntityType string             `query:"entity_type"`
	Limit      int
	Offset     int
}

type GetAuditLogResponse struct {
	Entries []entity.AuditEntry `json:"entries"`
	Total   int                 `json:"total"`
}
