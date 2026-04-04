package persistent

import (
	"context"

	"github.com/Megidy/BestLviv2026Test/internal/entity"
	"github.com/jackc/pgx/v5/pgxpool"
)

type MapRepo struct {
	pool *pgxpool.Pool
}

func NewMapRepo(pool *pgxpool.Pool) *MapRepo {
	return &MapRepo{pool: pool}
}

func (r *MapRepo) GetMapPoints(ctx context.Context) ([]entity.MapPoint, error) {
	const q = `
		SELECT c.id, c.name, 'customer' AS type, c.latitude, c.longitude,
		       COUNT(pa.id) FILTER (WHERE pa.status = 'open') AS alert_count,
		       CASE
		           WHEN COUNT(pa.id) FILTER (WHERE pa.status = 'open' AND pa.confidence >= 0.8) > 0 THEN 'critical'
		           WHEN COUNT(pa.id) FILTER (WHERE pa.status = 'open' AND pa.confidence >= 0.5) > 0 THEN 'elevated'
		           WHEN COUNT(pa.id) FILTER (WHERE pa.status = 'open') > 0 THEN 'predictive'
		           ELSE 'normal'
		       END AS status
		FROM customers c
		LEFT JOIN predictive_alerts pa ON pa.point_id = c.id
		GROUP BY c.id, c.name, c.latitude, c.longitude

		UNION ALL

		SELECT w.id, w.name, 'warehouse' AS type, w.latitude, w.longitude,
		       0 AS alert_count,
		       CASE
		           WHEN COALESCE(SUM(i.quantity), 0) = 0 THEN 'critical'
		           WHEN COALESCE(SUM(i.quantity), 0) < 50  THEN 'elevated'
		           ELSE 'normal'
		       END AS status
		FROM warehouses w
		LEFT JOIN inventories i ON i.warehouse_id = w.id
		GROUP BY w.id, w.name, w.latitude, w.longitude
	`

	rows, err := r.pool.Query(ctx, q)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var points []entity.MapPoint
	for rows.Next() {
		var p entity.MapPoint
		if err := rows.Scan(&p.ID, &p.Name, &p.Type, &p.Lat, &p.Lng, &p.AlertCount, &p.Status); err != nil {
			return nil, err
		}
		points = append(points, p)
	}
	return points, rows.Err()
}
