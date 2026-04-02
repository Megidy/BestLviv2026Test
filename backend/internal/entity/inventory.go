package entity

import "time"

type Inventory struct {
	Id         uint    `json:"id"`
	LocationId uint    `json:"location_id"`
	ResourceId uint    `json:"resource_id"`
	Quantity   float64 `json:"quantity"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
