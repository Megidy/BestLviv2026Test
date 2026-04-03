package entity

type MapPoint struct {
	ID         int64   `json:"id"`
	Name       string  `json:"name"`
	Type       string  `json:"type"` // "warehouse" | "customer"
	Lat        float64 `json:"lat"`
	Lng        float64 `json:"lng"`
	Status     string  `json:"status"` // "normal" | "elevated" | "critical" | "predictive"
	AlertCount int64   `json:"alert_count"`
}
