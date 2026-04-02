package entity

import "time"

type DeliveryPriority string
type DeliveryStatus string

type DeliveryRequest struct {
	ID            uint             `json:"id"`
	DestinationID uint             `json:"destination_id"`
	ResourceID    uint             `json:"resource_id"`
	UserId        uint             `json:"user_id"`
	Quantity      float64          `json:"quantity"`
	Priority      DeliveryPriority `json:"priority"`
	Status        DeliveryStatus   `json:"status"`
	IsUrgent      bool             `json:"is_urgent"`
	CreatedAt     time.Time        `json:"created_at"`
	UpdatedAt     time.Time        `json:"updated_at"`

	Allocations []Allocation `json:"allocations,omitempty"`
}
