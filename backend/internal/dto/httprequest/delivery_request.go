package httprequest

import (
	"time"

	"github.com/Megidy/BestLviv2026Test/internal/entity"
)

type Delivery struct {
	UserId        int
	DestinationId int                     `json:"destination_id" validate:"required"`
	ResourceIds   []DeliveryResourceData  `json:"data" validate:"required"`
	Priority      entity.DeliveryPriority `json:"priority" validate:"required"`
	ArriveTill    time.Time               `json:"arrive_till"`
}

type DeliveryResourceData struct {
	ResourceId int `json:"resource_id" validate:"required"`
	Quantity   int `json:"quantity" validate:"required"`
}
