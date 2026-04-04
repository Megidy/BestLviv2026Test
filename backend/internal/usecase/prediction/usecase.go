package prediction

import (
	"context"
	"fmt"
	"log/slog"
	"sort"
	"time"

	"github.com/Megidy/BestLviv2026Test/internal/entity"
)

type aiRepo interface {
	InsertDemandReading(ctx context.Context, d entity.DemandReading) (entity.DemandReading, error)
	GetLastNDemandReadings(ctx context.Context, pointID, resourceID uint, n int) ([]entity.DemandReading, error)
	GetDemandReadingsByPoint(ctx context.Context, pointID uint, limit, offset int) ([]entity.DemandReading, int, error)
	GetAllActivePointResourcePairs(ctx context.Context) ([]entity.PointResourcePair, error)
	GetInventoryByResource(ctx context.Context, resourceID uint) ([]entity.WarehouseInventory, error)
	GetTotalStockForResource(ctx context.Context, resourceID uint) (float64, error)
	GetCustomerCoords(ctx context.Context, customerID uint) (lat, lon float64, err error)
	GetCustomerName(ctx context.Context, customerID uint) (string, error)
	GetResourceName(ctx context.Context, resourceID uint) (string, error)
	InsertPredictiveAlert(ctx context.Context, a entity.PredictiveAlert) (entity.PredictiveAlert, error)
	GetAlertByID(ctx context.Context, id uint) (entity.PredictiveAlert, error)
	GetOpenAlertByPointAndResource(ctx context.Context, pointID, resourceID uint) (entity.PredictiveAlert, bool, error)
	GetOpenAlerts(ctx context.Context, limit, offset int) ([]entity.PredictiveAlert, int, error)
	GetAlertsByPoint(ctx context.Context, pointID uint) ([]entity.PredictiveAlert, error)
	UpdateAlertStatus(ctx context.Context, id uint, status entity.AlertStatus, proposalID *uint) error
	InsertProposalWithTransfers(ctx context.Context, p entity.RebalancingProposal, transfers []entity.RebalancingTransfer) (entity.RebalancingProposal, error)
	GetProposalByID(ctx context.Context, id uint) (entity.RebalancingProposal, error)
	UpdateProposalStatus(ctx context.Context, id uint, status entity.ProposalStatus) error
}

// llmClient generates human-readable rationale for alerts. Optional — pass nil to skip.
type llmClient interface {
	GenerateRationale(ctx context.Context, prompt string) (string, error)
}

type UseCase struct {
	repo   aiRepo
	llm    llmClient // nil → rationale generation skipped
	logger *slog.Logger
}

func New(repo aiRepo, llm llmClient, logger *slog.Logger) *UseCase {
	return &UseCase{repo: repo, llm: llm, logger: logger}
}

// StartPredictionLoop runs RunPredictions on the given interval until ctx is cancelled.
func (u *UseCase) StartPredictionLoop(ctx context.Context, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	u.logger.Info("prediction loop started", "interval", interval)
	for {
		select {
		case <-ctx.Done():
			u.logger.Info("prediction loop stopped")
			return
		case <-ticker.C:
			if err := u.RunPredictions(ctx); err != nil {
				u.logger.Error("prediction run failed", "error", err)
			}
		}
	}
}

// RunPredictions scans all active (point, resource) pairs and creates predictive alerts
// for those that are trending toward shortage.
func (u *UseCase) RunPredictions(ctx context.Context) error {
	pairs, err := u.repo.GetAllActivePointResourcePairs(ctx)
	if err != nil {
		return fmt.Errorf("get pairs: %w", err)
	}

	for _, pair := range pairs {
		if err := u.analyzePair(ctx, pair.PointID, pair.ResourceID); err != nil {
			u.logger.Warn("analyze pair failed", "point_id", pair.PointID, "resource_id", pair.ResourceID, "error", err)
		}
	}
	return nil
}

func (u *UseCase) analyzePair(ctx context.Context, pointID, resourceID uint) error {
	readings, err := u.repo.GetLastNDemandReadings(ctx, pointID, resourceID, longWindow)
	if err != nil {
		return err
	}

	points := toDemandPoints(readings)
	analysis := Analyze(points)
	if !analysis.IsTrending {
		return nil
	}

	// Don't create duplicate open alerts
	_, exists, err := u.repo.GetOpenAlertByPointAndResource(ctx, pointID, resourceID)
	if err != nil || exists {
		return err
	}

	totalStock, err := u.repo.GetTotalStockForResource(ctx, resourceID)
	if err != nil {
		return err
	}

	intervalHours := AvgIntervalHours(points)
	hoursToShortfall := ShortfallHours(totalStock, analysis.ShortTermAvg, intervalHours)
	if hoursToShortfall < 0 || hoursToShortfall > shortfallHorizon {
		return nil
	}

	alert := entity.PredictiveAlert{
		PointID:              pointID,
		ResourceID:           resourceID,
		PredictedShortfallAt: time.Now().Add(time.Duration(hoursToShortfall * float64(time.Hour))),
		Confidence:           analysis.Confidence,
		Status:               entity.AlertStatusOpen,
		Rationale:            u.generateRationale(ctx, pointID, resourceID, analysis, hoursToShortfall),
	}
	alert, err = u.repo.InsertPredictiveAlert(ctx, alert)
	if err != nil {
		return fmt.Errorf("insert alert: %w", err)
	}

	proposal, err := u.generateRebalancingProposal(ctx, alert, analysis)
	if err != nil {
		u.logger.Warn("could not generate rebalancing proposal", "alert_id", alert.ID, "error", err)
		return nil
	}

	pid := proposal.ID
	return u.repo.UpdateAlertStatus(ctx, alert.ID, entity.AlertStatusOpen, &pid)
}

func (u *UseCase) generateRebalancingProposal(ctx context.Context, alert entity.PredictiveAlert, analysis Analysis) (entity.RebalancingProposal, error) {
	warehouseStocks, err := u.repo.GetInventoryByResource(ctx, alert.ResourceID)
	if err != nil {
		return entity.RebalancingProposal{}, err
	}

	customerLat, customerLon, err := u.repo.GetCustomerCoords(ctx, alert.PointID)
	if err != nil {
		return entity.RebalancingProposal{}, err
	}

	type candidate struct {
		warehouseID uint
		surplus     float64
		distKm      float64
	}

	var candidates []candidate
	var maxDist float64

	for _, ws := range warehouseStocks {
		surplus := ws.Quantity * (1 - safetyStockRatio)
		if surplus <= 0 {
			continue
		}
		d := HaversineKm(ws.Lat, ws.Lon, customerLat, customerLon)
		candidates = append(candidates, candidate{ws.WarehouseID, surplus, d})
		if d > maxDist {
			maxDist = d
		}
	}

	if len(candidates) == 0 {
		return entity.RebalancingProposal{}, entity.ErrNoSuppliersAvailable
	}

	sort.Slice(candidates, func(i, j int) bool {
		ni := candidates[i].distKm / maxDist
		nj := candidates[j].distKm / maxDist
		return SupplierScore(candidates[i].surplus, ni) > SupplierScore(candidates[j].surplus, nj)
	})

	neededQty := analysis.ShortTermAvg * 2 // buffer for 2 demand periods
	var transfers []entity.RebalancingTransfer
	remaining := neededQty

	for _, c := range candidates {
		if remaining <= 0 {
			break
		}
		qty := c.surplus
		if qty > remaining {
			qty = remaining
		}
		transfers = append(transfers, entity.RebalancingTransfer{
			FromWarehouseID:       c.warehouseID,
			Quantity:              qty,
			EstimatedArrivalHours: ArrivalHours(c.distKm),
		})
		remaining -= qty
	}

	proposal := entity.RebalancingProposal{
		TargetPointID: alert.PointID,
		ResourceID:    alert.ResourceID,
		Urgency:       "predictive",
		Confidence:    alert.Confidence,
		Status:        entity.ProposalStatusPending,
	}

	return u.repo.InsertProposalWithTransfers(ctx, proposal, transfers)
}

// RecordDemand stores a new demand reading and optionally triggers analysis for that pair.
func (u *UseCase) RecordDemand(ctx context.Context, d entity.DemandReading) (entity.DemandReading, error) {
	result, err := u.repo.InsertDemandReading(ctx, d)
	if err != nil {
		return entity.DemandReading{}, err
	}
	// Best-effort: run analysis for this pair in the background after recording
	go func() {
		bCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := u.analyzePair(bCtx, d.PointID, d.ResourceID); err != nil {
			u.logger.Warn("post-record analysis failed", "error", err)
		}
	}()
	return result, nil
}

func (u *UseCase) GetDemandReadings(ctx context.Context, pointID uint, limit, offset int) ([]entity.DemandReading, int, error) {
	return u.repo.GetDemandReadingsByPoint(ctx, pointID, limit, offset)
}

func (u *UseCase) GetOpenAlerts(ctx context.Context, limit, offset int) ([]entity.PredictiveAlert, int, error) {
	return u.repo.GetOpenAlerts(ctx, limit, offset)
}

func (u *UseCase) GetAlertsByPoint(ctx context.Context, pointID uint) ([]entity.PredictiveAlert, error) {
	return u.repo.GetAlertsByPoint(ctx, pointID)
}

func (u *UseCase) DismissAlert(ctx context.Context, alertID uint) error {
	alert, err := u.repo.GetAlertByID(ctx, alertID)
	if err != nil {
		return err
	}
	if alert.Status != entity.AlertStatusOpen {
		return entity.ErrAlreadyResolved
	}
	return u.repo.UpdateAlertStatus(ctx, alertID, entity.AlertStatusDismissed, alert.ProposalID)
}

func (u *UseCase) GetProposal(ctx context.Context, proposalID uint) (entity.RebalancingProposal, error) {
	return u.repo.GetProposalByID(ctx, proposalID)
}

func (u *UseCase) ApproveProposal(ctx context.Context, proposalID uint) (entity.RebalancingProposal, error) {
	proposal, err := u.repo.GetProposalByID(ctx, proposalID)
	if err != nil {
		return entity.RebalancingProposal{}, err
	}
	if proposal.Status != entity.ProposalStatusPending {
		return entity.RebalancingProposal{}, entity.ErrAlreadyResolved
	}
	if err := u.repo.UpdateProposalStatus(ctx, proposalID, entity.ProposalStatusApproved); err != nil {
		return entity.RebalancingProposal{}, err
	}
	proposal.Status = entity.ProposalStatusApproved
	return proposal, nil
}

func (u *UseCase) DismissProposal(ctx context.Context, proposalID uint) error {
	proposal, err := u.repo.GetProposalByID(ctx, proposalID)
	if err != nil {
		return err
	}
	if proposal.Status != entity.ProposalStatusPending {
		return entity.ErrAlreadyResolved
	}
	return u.repo.UpdateProposalStatus(ctx, proposalID, entity.ProposalStatusDismissed)
}

// generateRationale calls the LLM to produce a 2-sentence human-readable explanation.
// Returns nil if LLM is not configured or the call fails (best-effort).
func (u *UseCase) generateRationale(ctx context.Context, pointID, resourceID uint, analysis Analysis, hoursToShortfall float64) *string {
	if u.llm == nil {
		return nil
	}

	customerName, _ := u.repo.GetCustomerName(ctx, pointID)
	if customerName == "" {
		customerName = fmt.Sprintf("point #%d", pointID)
	}
	resourceName, _ := u.repo.GetResourceName(ctx, resourceID)
	if resourceName == "" {
		resourceName = fmt.Sprintf("resource #%d", resourceID)
	}

	prompt := fmt.Sprintf(
		`You are a logistics operations AI assistant. Write exactly 2 concise sentences about a predicted shortage alert. Be specific with the numbers provided.

Location: %s
Resource: %s
Short-term demand average (last 3 periods): %.1f units
Long-term demand average (last 14 periods): %.1f units
Demand increase above baseline: %.0f%%
Predicted shortfall in: %.0f hours
Alert confidence: %.0f%%

First sentence: describe what is happening with demand and why it's a concern.
Second sentence: state the recommended action and urgency. Do not add any extra sentences or formatting.`,
		customerName, resourceName,
		analysis.ShortTermAvg, analysis.LongTermAvg,
		analysis.DivergenceRatio*100,
		hoursToShortfall,
		analysis.Confidence*100,
	)

	rationale, err := u.llm.GenerateRationale(ctx, prompt)
	if err != nil {
		u.logger.Warn("rationale generation failed", "point_id", pointID, "resource_id", resourceID, "error", err)
		return nil
	}
	return &rationale
}

func toDemandPoints(readings []entity.DemandReading) []DemandPoint {
	pts := make([]DemandPoint, len(readings))
	for i, r := range readings {
		pts[i] = DemandPoint{Quantity: r.Quantity, RecordedAt: r.RecordedAt}
	}
	return pts
}
