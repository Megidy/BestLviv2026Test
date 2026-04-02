package entity

import "time"

type AlertStatus string

type PredictiveAlert struct {
	ID                   uint        `json:"id"`
	PointID              uint        `json:"point_id"`
	ResourceID           uint        `json:"resource_id"`
	PredictedShortfallAt time.Time   `json:"predicted_shortfall_at"`
	Confidence           float64     `json:"confidence"`
	Status               AlertStatus `json:"status"`
	ProposalID           *uint       `json:"proposal_id,omitempty"`
	CreatedAt            time.Time   `json:"created_at"`
	UpdatedAt            time.Time   `json:"updated_at"`
}
