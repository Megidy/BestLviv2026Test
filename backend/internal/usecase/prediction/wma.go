package prediction

import (
	"math"
	"time"
)

const (
	shortWindow         = 3
	longWindow          = 14
	divergenceThreshold = 0.20 // 20% short-term divergence above long-term triggers alert
	minReadings         = 5
	shortfallHorizon    = 48.0 // only alert if shortfall within 48 hours
	safetyStockRatio    = 0.20 // warehouses keep 20% as safety stock
	avgSpeedKmH         = 60.0 // assumed delivery speed for arrival estimation
	earthRadiusKm       = 6371.0
)

// DemandPoint is a single demand reading with its timestamp.
type DemandPoint struct {
	Quantity   float64
	RecordedAt time.Time
}

// Analysis is the result of running WMA on a series of demand readings.
type Analysis struct {
	ShortTermAvg    float64
	LongTermAvg     float64
	DivergenceRatio float64
	IsTrending      bool
	Confidence      float64 // 0.0–1.0
}

// Analyze runs weighted moving average analysis on the provided readings.
// readings must be ordered oldest → newest.
func Analyze(readings []DemandPoint) Analysis {
	if len(readings) < minReadings {
		return Analysis{}
	}

	quantities := make([]float64, len(readings))
	for i, r := range readings {
		quantities[i] = r.Quantity
	}

	shortAvg := weightedAvgTail(quantities, shortWindow)
	longAvg := weightedAvgTail(quantities, longWindow)

	if longAvg == 0 {
		return Analysis{}
	}

	divergence := (shortAvg - longAvg) / longAvg
	trending := divergence >= divergenceThreshold

	var confidence float64
	if trending {
		// 0.5 at threshold, grows to 1.0 as divergence doubles the threshold
		confidence = math.Min(0.5+(divergence-divergenceThreshold)/(2*divergenceThreshold), 1.0)
	}

	return Analysis{
		ShortTermAvg:    shortAvg,
		LongTermAvg:     longAvg,
		DivergenceRatio: divergence,
		IsTrending:      trending,
		Confidence:      confidence,
	}
}

// ShortfallHours estimates hours until stock runs out given the current demand rate.
// Returns a negative value if demand rate is zero or stock is infinite.
func ShortfallHours(currentStock, shortTermDemandPerPeriod, avgIntervalHours float64) float64 {
	if shortTermDemandPerPeriod <= 0 {
		return -1
	}
	periods := currentStock / shortTermDemandPerPeriod
	return periods * avgIntervalHours
}

// AvgIntervalHours calculates the mean time between readings (in hours).
// readings must be ordered oldest → newest.
func AvgIntervalHours(readings []DemandPoint) float64 {
	if len(readings) < 2 {
		return 24.0 // assume daily if not enough data
	}
	total := readings[len(readings)-1].RecordedAt.Sub(readings[0].RecordedAt)
	return total.Hours() / float64(len(readings)-1)
}

// HaversineKm returns the great-circle distance in km between two lat/lon points.
func HaversineKm(lat1, lon1, lat2, lon2 float64) float64 {
	dLat := (lat2 - lat1) * math.Pi / 180
	dLon := (lon2 - lon1) * math.Pi / 180
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180)*math.Cos(lat2*math.Pi/180)*
			math.Sin(dLon/2)*math.Sin(dLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return earthRadiusKm * c
}

// ArrivalHours converts a distance in km to estimated travel hours.
func ArrivalHours(distanceKm float64) float64 {
	return distanceKm / avgSpeedKmH
}

// SupplierScore ranks a warehouse candidate for rebalancing.
// Higher is better. surplus and normalizedDist are both in [0,1] scale.
func SupplierScore(surplus, normalizedDist float64) float64 {
	return surplus*0.6 - normalizedDist*0.4
}

// weightedAvgTail computes a linearly weighted average of the last n values.
// More recent values receive higher weights.
func weightedAvgTail(values []float64, n int) float64 {
	tail := values
	if len(tail) > n {
		tail = tail[len(tail)-n:]
	}
	var sum, weightSum float64
	for i, v := range tail {
		w := float64(i + 1)
		sum += v * w
		weightSum += w
	}
	if weightSum == 0 {
		return 0
	}
	return sum / weightSum
}
