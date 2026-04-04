package httprequest

import (
	"time"

	"github.com/Megidy/BestLviv2026Test/internal/entity"
)

type RecordDemand struct {
	PointID    uint                 `json:"point_id"    validate:"required"`
	ResourceID uint                 `json:"resource_id" validate:"required"`
	Quantity   float64              `json:"quantity"    validate:"required,gt=0"`
	Source     entity.DemandSource  `json:"source"      validate:"omitempty,oneof=manual sensor predicted"`
	RecordedAt *time.Time           `json:"recorded_at"`
}
