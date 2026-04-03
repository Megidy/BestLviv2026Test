package dto

import (
	"time"

	"github.com/Megidy/BestLviv2026Test/internal/entity"
)

// RichAlert joins predictive_alerts with customer and resource names.
type RichAlert struct {
	ID                   uint               `json:"id"`
	PointID              uint               `json:"point_id"`
	PointName            string             `json:"point_name"`
	ResourceID           uint               `json:"resource_id"`
	ResourceName         string             `json:"resource_name"`
	PredictedShortfallAt time.Time          `json:"predicted_shortfall_at"`
	Confidence           float64            `json:"confidence"`
	Status               entity.AlertStatus `json:"status"`
	ProposalID           *uint              `json:"proposal_id,omitempty"`
	CreatedAt            time.Time          `json:"created_at"`
	UpdatedAt            time.Time          `json:"updated_at"`
}

type GetRichAlertsResponse struct {
	Alerts []RichAlert `json:"alerts"`
	Total  int         `json:"total"`
}
