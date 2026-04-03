package entity

import "time"

type DeliveryPriority string
type DeliveryStatus string

type DeliveryRequest struct {
	ID            uint             `json:"id"`
	DestinationID uint             `json:"destination_id"`
	ResourceID    uint             `json:"resource_id"`
	UserID        uint             `json:"user_id"`
	Quantity      float64          `json:"quantity"`
	Priority      DeliveryPriority `json:"priority"`
	Status        DeliveryStatus   `json:"status"`
	ArriveTill    *time.Time       `json:"arrive_till,omitempty"`
	CreatedAt     time.Time        `json:"created_at"`
	UpdatedAt     time.Time        `json:"updated_at"`

	Items       []DeliveryRequestItem `json:"items,omitempty"`
	Allocations []Allocation          `json:"allocations,omitempty"`
}

type DeliveryRequestItem struct {
	ID         uint      `json:"id"`
	RequestID  uint      `json:"request_id"`
	ResourceID uint      `json:"resource_id"`
	Quantity   float64   `json:"quantity"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}
