package httprequest

import (
	"time"

	"github.com/Megidy/BestLviv2026Test/internal/entity"
)

type CreateDeliveryRequest struct {
	DestinationID uint                    `json:"destination_id" validate:"required"`
	Items         []DeliveryItemRequest   `json:"items"          validate:"required,min=1,dive"`
	Priority      entity.DeliveryPriority `json:"priority"       validate:"required,oneof=normal elevated critical urgent"`
	ArriveTill    *time.Time              `json:"arrive_till"`
}

type DeliveryItemRequest struct {
	ResourceID uint    `json:"resource_id" validate:"required"`
	Quantity   float64 `json:"quantity"    validate:"required,gt=0"`
}

type RejectAllocationRequest struct {
	Reason string `json:"reason" validate:"required"`
}

type UpdateItemQuantityRequest struct {
	ResourceID uint    `json:"resource_id" validate:"required"`
	Quantity   float64 `json:"quantity"    validate:"required,gt=0"`
}

// kept for backward-compat with the existing stub
type Delivery struct {
	UserId        int
	DestinationId int                   `json:"destination_id" validate:"required"`
	ResourceIds   []DeliveryResourceData `json:"data"           validate:"required"`
	Priority      entity.DeliveryPriority `json:"priority"      validate:"required"`
	ArriveTill    time.Time              `json:"arrive_till"`
}

type DeliveryResourceData struct {
	ResourceId int `json:"resource_id" validate:"required"`
	Quantity   int `json:"quantity"    validate:"required"`
}
