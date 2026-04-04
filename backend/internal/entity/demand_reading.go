package entity

import "time"

type DemandSource string

type DemandReading struct {
	ID         uint         `json:"id"`
	PointID    uint         `json:"point_id"`
	ResourceID uint         `json:"resource_id"`
	Quantity   float64      `json:"quantity"`
	RecordedAt time.Time    `json:"recorded_at"`
	Source     DemandSource `json:"source"`
	CreatedAt  time.Time    `json:"created_at"`
}
