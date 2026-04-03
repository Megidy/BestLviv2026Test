package persistent

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/Megidy/BestLviv2026Test/internal/entity"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type AIRepo struct {
	pool *pgxpool.Pool
}

func NewAIRepo(pool *pgxpool.Pool) *AIRepo {
	return &AIRepo{pool: pool}
}

// --- Demand Readings ---

func (r *AIRepo) InsertDemandReading(ctx context.Context, d entity.DemandReading) (entity.DemandReading, error) {
	if d.RecordedAt.IsZero() {
		d.RecordedAt = time.Now()
	}
	err := r.pool.QueryRow(ctx,
		`INSERT INTO demand_readings (point_id, resource_id, quantity, recorded_at, source)
		 VALUES ($1, $2, $3, $4, $5)
		 RETURNING id, created_at`,
		d.PointID, d.ResourceID, d.Quantity, d.RecordedAt, d.Source,
	).Scan(&d.ID, &d.CreatedAt)
	if err != nil {
		return entity.DemandReading{}, fmt.Errorf("insert demand reading: %w", err)
	}
	return d, nil
}

func (r *AIRepo) GetLastNDemandReadings(ctx context.Context, pointID, resourceID uint, n int) ([]entity.DemandReading, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, point_id, resource_id, quantity, recorded_at, source, created_at
		 FROM demand_readings
		 WHERE point_id = $1 AND resource_id = $2
		 ORDER BY recorded_at DESC
		 LIMIT $3`,
		pointID, resourceID, n,
	)
	if err != nil {
		return nil, fmt.Errorf("get last n demand readings: %w", err)
	}
	defer rows.Close()

	var readings []entity.DemandReading
	for rows.Next() {
		var d entity.DemandReading
		if err := rows.Scan(&d.ID, &d.PointID, &d.ResourceID, &d.Quantity, &d.RecordedAt, &d.Source, &d.CreatedAt); err != nil {
			return nil, fmt.Errorf("scan demand reading: %w", err)
		}
		readings = append(readings, d)
	}
	// Reverse so oldest is first (WMA expects oldest→newest)
	for i, j := 0, len(readings)-1; i < j; i, j = i+1, j-1 {
		readings[i], readings[j] = readings[j], readings[i]
	}
	return readings, rows.Err()
}

func (r *AIRepo) GetDemandReadingsByPoint(ctx context.Context, pointID uint, limit, offset int) ([]entity.DemandReading, int, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, point_id, resource_id, quantity, recorded_at, source, created_at,
		        COUNT(*) OVER() AS total
		 FROM demand_readings
		 WHERE point_id = $1
		 ORDER BY recorded_at DESC
		 LIMIT $2 OFFSET $3`,
		pointID, limit, offset,
	)
	if err != nil {
		return nil, 0, fmt.Errorf("get demand readings by point: %w", err)
	}
	defer rows.Close()

	var (
		readings []entity.DemandReading
		total    int
	)
	for rows.Next() {
		var d entity.DemandReading
		if err := rows.Scan(&d.ID, &d.PointID, &d.ResourceID, &d.Quantity, &d.RecordedAt, &d.Source, &d.CreatedAt, &total); err != nil {
			return nil, 0, fmt.Errorf("scan demand reading: %w", err)
		}
		readings = append(readings, d)
	}
	return readings, total, rows.Err()
}

func (r *AIRepo) GetAllActivePointResourcePairs(ctx context.Context) ([]entity.PointResourcePair, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT DISTINCT point_id, resource_id FROM demand_readings`,
	)
	if err != nil {
		return nil, fmt.Errorf("get active pairs: %w", err)
	}
	defer rows.Close()

	var pairs []entity.PointResourcePair
	for rows.Next() {
		var p entity.PointResourcePair
		if err := rows.Scan(&p.PointID, &p.ResourceID); err != nil {
			return nil, fmt.Errorf("scan pair: %w", err)
		}
		pairs = append(pairs, p)
	}
	return pairs, rows.Err()
}

// --- Inventory / Location queries for rebalancing ---

func (r *AIRepo) GetInventoryByResource(ctx context.Context, resourceID uint) ([]entity.WarehouseInventory, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT i.warehouse_id, i.quantity, w.latitude, w.longitude
		 FROM inventories i
		 JOIN warehouses w ON i.warehouse_id = w.id
		 WHERE i.resource_id = $1 AND i.quantity > 0`,
		resourceID,
	)
	if err != nil {
		return nil, fmt.Errorf("get inventory by resource: %w", err)
	}
	defer rows.Close()

	var result []entity.WarehouseInventory
	for rows.Next() {
		var w entity.WarehouseInventory
		if err := rows.Scan(&w.WarehouseID, &w.Quantity, &w.Lat, &w.Lon); err != nil {
			return nil, fmt.Errorf("scan warehouse inventory: %w", err)
		}
		result = append(result, w) // Name intentionally empty — not needed by AI module
	}
	return result, rows.Err()
}

func (r *AIRepo) GetTotalStockForResource(ctx context.Context, resourceID uint) (float64, error) {
	var total float64
	err := r.pool.QueryRow(ctx,
		`SELECT COALESCE(SUM(quantity), 0) FROM inventories WHERE resource_id = $1`,
		resourceID,
	).Scan(&total)
	return total, err
}

func (r *AIRepo) GetCustomerCoords(ctx context.Context, customerID uint) (lat, lon float64, err error) {
	err = r.pool.QueryRow(ctx,
		`SELECT latitude, longitude FROM customers WHERE id = $1`,
		customerID,
	).Scan(&lat, &lon)
	if errors.Is(err, pgx.ErrNoRows) {
		return 0, 0, entity.ErrNotFound
	}
	return lat, lon, err
}

// --- Predictive Alerts ---

func (r *AIRepo) InsertPredictiveAlert(ctx context.Context, a entity.PredictiveAlert) (entity.PredictiveAlert, error) {
	err := r.pool.QueryRow(ctx,
		`INSERT INTO predictive_alerts (point_id, resource_id, predicted_shortfall_at, confidence, status)
		 VALUES ($1, $2, $3, $4, $5)
		 RETURNING id, created_at, updated_at`,
		a.PointID, a.ResourceID, a.PredictedShortfallAt, a.Confidence, a.Status,
	).Scan(&a.ID, &a.CreatedAt, &a.UpdatedAt)
	if err != nil {
		return entity.PredictiveAlert{}, fmt.Errorf("insert predictive alert: %w", err)
	}
	return a, nil
}

func (r *AIRepo) GetAlertByID(ctx context.Context, id uint) (entity.PredictiveAlert, error) {
	var a entity.PredictiveAlert
	err := r.pool.QueryRow(ctx,
		`SELECT id, point_id, resource_id, predicted_shortfall_at, confidence, status, proposal_id, created_at, updated_at
		 FROM predictive_alerts WHERE id = $1`,
		id,
	).Scan(&a.ID, &a.PointID, &a.ResourceID, &a.PredictedShortfallAt, &a.Confidence, &a.Status, &a.ProposalID, &a.CreatedAt, &a.UpdatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return entity.PredictiveAlert{}, entity.ErrNotFound
	}
	return a, err
}

func (r *AIRepo) GetOpenAlertByPointAndResource(ctx context.Context, pointID, resourceID uint) (entity.PredictiveAlert, bool, error) {
	var a entity.PredictiveAlert
	err := r.pool.QueryRow(ctx,
		`SELECT id, point_id, resource_id, predicted_shortfall_at, confidence, status, proposal_id, created_at, updated_at
		 FROM predictive_alerts
		 WHERE point_id = $1 AND resource_id = $2 AND status = 'open'
		 LIMIT 1`,
		pointID, resourceID,
	).Scan(&a.ID, &a.PointID, &a.ResourceID, &a.PredictedShortfallAt, &a.Confidence, &a.Status, &a.ProposalID, &a.CreatedAt, &a.UpdatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return entity.PredictiveAlert{}, false, nil
	}
	if err != nil {
		return entity.PredictiveAlert{}, false, err
	}
	return a, true, nil
}

func (r *AIRepo) GetOpenAlerts(ctx context.Context, limit, offset int) ([]entity.PredictiveAlert, int, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, point_id, resource_id, predicted_shortfall_at, confidence, status, proposal_id, created_at, updated_at,
		        COUNT(*) OVER() AS total
		 FROM predictive_alerts
		 WHERE status = 'open'
		 ORDER BY confidence DESC, predicted_shortfall_at ASC
		 LIMIT $1 OFFSET $2`,
		limit, offset,
	)
	if err != nil {
		return nil, 0, fmt.Errorf("get open alerts: %w", err)
	}
	defer rows.Close()

	var (
		alerts []entity.PredictiveAlert
		total  int
	)
	for rows.Next() {
		var a entity.PredictiveAlert
		if err := rows.Scan(&a.ID, &a.PointID, &a.ResourceID, &a.PredictedShortfallAt, &a.Confidence, &a.Status, &a.ProposalID, &a.CreatedAt, &a.UpdatedAt, &total); err != nil {
			return nil, 0, fmt.Errorf("scan alert: %w", err)
		}
		alerts = append(alerts, a)
	}
	return alerts, total, rows.Err()
}

func (r *AIRepo) GetAlertsByPoint(ctx context.Context, pointID uint) ([]entity.PredictiveAlert, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, point_id, resource_id, predicted_shortfall_at, confidence, status, proposal_id, created_at, updated_at
		 FROM predictive_alerts
		 WHERE point_id = $1
		 ORDER BY created_at DESC`,
		pointID,
	)
	if err != nil {
		return nil, fmt.Errorf("get alerts by point: %w", err)
	}
	defer rows.Close()

	var alerts []entity.PredictiveAlert
	for rows.Next() {
		var a entity.PredictiveAlert
		if err := rows.Scan(&a.ID, &a.PointID, &a.ResourceID, &a.PredictedShortfallAt, &a.Confidence, &a.Status, &a.ProposalID, &a.CreatedAt, &a.UpdatedAt); err != nil {
			return nil, fmt.Errorf("scan alert: %w", err)
		}
		alerts = append(alerts, a)
	}
	return alerts, rows.Err()
}

func (r *AIRepo) UpdateAlertStatus(ctx context.Context, id uint, status entity.AlertStatus, proposalID *uint) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE predictive_alerts SET status = $1, proposal_id = $2 WHERE id = $3`,
		status, proposalID, id,
	)
	return err
}

// --- Rebalancing Proposals ---

func (r *AIRepo) InsertProposalWithTransfers(ctx context.Context, p entity.RebalancingProposal, transfers []entity.RebalancingTransfer) (entity.RebalancingProposal, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return entity.RebalancingProposal{}, fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	err = tx.QueryRow(ctx,
		`INSERT INTO rebalancing_proposals (target_point_id, resource_id, urgency, confidence, status)
		 VALUES ($1, $2, $3, $4, $5)
		 RETURNING id, created_at, updated_at`,
		p.TargetPointID, p.ResourceID, p.Urgency, p.Confidence, p.Status,
	).Scan(&p.ID, &p.CreatedAt, &p.UpdatedAt)
	if err != nil {
		return entity.RebalancingProposal{}, fmt.Errorf("insert proposal: %w", err)
	}

	for i := range transfers {
		transfers[i].ProposalID = p.ID
		err = tx.QueryRow(ctx,
			`INSERT INTO rebalancing_transfers (proposal_id, from_warehouse_id, quantity, estimated_arrival_hours)
			 VALUES ($1, $2, $3, $4)
			 RETURNING id, created_at`,
			transfers[i].ProposalID, transfers[i].FromWarehouseID, transfers[i].Quantity, transfers[i].EstimatedArrivalHours,
		).Scan(&transfers[i].ID, &transfers[i].CreatedAt)
		if err != nil {
			return entity.RebalancingProposal{}, fmt.Errorf("insert transfer: %w", err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return entity.RebalancingProposal{}, fmt.Errorf("commit tx: %w", err)
	}

	p.Transfers = transfers
	return p, nil
}

func (r *AIRepo) GetProposalByID(ctx context.Context, id uint) (entity.RebalancingProposal, error) {
	var p entity.RebalancingProposal
	err := r.pool.QueryRow(ctx,
		`SELECT id, target_point_id, resource_id, urgency, confidence, status, created_at, updated_at
		 FROM rebalancing_proposals WHERE id = $1`,
		id,
	).Scan(&p.ID, &p.TargetPointID, &p.ResourceID, &p.Urgency, &p.Confidence, &p.Status, &p.CreatedAt, &p.UpdatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return entity.RebalancingProposal{}, entity.ErrNotFound
	}
	if err != nil {
		return entity.RebalancingProposal{}, err
	}

	rows, err := r.pool.Query(ctx,
		`SELECT id, proposal_id, from_warehouse_id, quantity, estimated_arrival_hours, created_at
		 FROM rebalancing_transfers WHERE proposal_id = $1`,
		id,
	)
	if err != nil {
		return entity.RebalancingProposal{}, fmt.Errorf("get transfers: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var t entity.RebalancingTransfer
		if err := rows.Scan(&t.ID, &t.ProposalID, &t.FromWarehouseID, &t.Quantity, &t.EstimatedArrivalHours, &t.CreatedAt); err != nil {
			return entity.RebalancingProposal{}, fmt.Errorf("scan transfer: %w", err)
		}
		p.Transfers = append(p.Transfers, t)
	}
	return p, rows.Err()
}

func (r *AIRepo) UpdateProposalStatus(ctx context.Context, id uint, status entity.ProposalStatus) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE rebalancing_proposals SET status = $1 WHERE id = $2`,
		status, id,
	)
	return err
}
