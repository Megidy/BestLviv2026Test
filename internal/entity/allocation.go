package entity

import "time"

type Allocation struct {
	ID               uint    `json:"id"`
	RequestID        uint    `json:"request_id"`
	SourceLocationID uint    `json:"source_location_id"`
	Quantity         float64 `json:"quantity"`
	// Status           Status  `json:"status"`

	DispatchedAt time.Time `json:"dispatched_at"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
