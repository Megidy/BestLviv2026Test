package entity

import "time"

type Resource struct {
	Id          int    `json:"resource"`
	Name        string `json:"name"`
	Category    string `json:"category"`
	UnitMeasure string `json:"unit_measure"`
	LogoUri     string `json:"logo_uri"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
