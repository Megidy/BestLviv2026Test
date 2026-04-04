package entity

import "time"

type AllocationStatus string

type Allocation struct {
	ID                uint             `json:"id"`
	RequestID         uint             `json:"request_id"`
	SourceWarehouseID uint             `json:"source_warehouse_id"`
	ResourceID        uint             `json:"resource_id"`
	Quantity          float64          `json:"quantity"`
	Status            AllocationStatus `json:"status"`
	DispatchedAt      *time.Time       `json:"dispatched_at,omitempty"`
	CreatedAt         time.Time        `json:"created_at"`
	UpdatedAt         time.Time        `json:"updated_at"`
}
