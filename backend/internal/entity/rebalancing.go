package entity

import "time"

type ProposalStatus string

type RebalancingProposal struct {
	ID            uint                 `json:"id"`
	TargetPointID uint                 `json:"target_point_id"`
	ResourceID    uint                 `json:"resource_id"`
	Urgency       string               `json:"urgency"`
	Confidence    float64              `json:"confidence"`
	Status        ProposalStatus       `json:"status"`
	Transfers     []RebalancingTransfer `json:"transfers,omitempty"`
	CreatedAt     time.Time            `json:"created_at"`
	UpdatedAt     time.Time            `json:"updated_at"`
}

type RebalancingTransfer struct {
	ID                    uint      `json:"id"`
	ProposalID            uint      `json:"proposal_id"`
	FromWarehouseID       uint      `json:"from_warehouse_id"`
	Quantity              float64   `json:"quantity"`
	EstimatedArrivalHours float64   `json:"estimated_arrival_hours"`
	CreatedAt             time.Time `json:"created_at"`
}

// WarehouseInventory is used internally by the AI module for rebalancing calculations.
type WarehouseInventory struct {
	WarehouseID uint
	Quantity    float64
	Lat         float64
	Lon         float64
}

// PointResourcePair identifies a unique (delivery point, resource) combination.
type PointResourcePair struct {
	PointID    uint
	ResourceID uint
}
