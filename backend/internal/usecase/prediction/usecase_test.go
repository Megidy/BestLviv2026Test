package prediction

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"math"
	"testing"
	"time"

	"github.com/Megidy/BestLviv2026Test/internal/entity"
)

type stubAIRepo struct {
	readings          []entity.DemandReading
	pairs             []entity.PointResourcePair
	totalStock        float64
	warehouseStocks   []entity.WarehouseInventory
	customerCoords    map[uint][2]float64
	openAlert         entity.PredictiveAlert
	openAlertExists   bool
	alertByID         entity.PredictiveAlert
	proposalByID      entity.RebalancingProposal
	insertedAlert     *entity.PredictiveAlert
	insertedProposal  *entity.RebalancingProposal
	insertedTransfers []entity.RebalancingTransfer
	updatedAlertID    uint
	updatedAlertState entity.AlertStatus
	updatedProposalID uint
	updatedProposal   entity.ProposalStatus
}

func (s *stubAIRepo) InsertDemandReading(ctx context.Context, d entity.DemandReading) (entity.DemandReading, error) {
	return d, nil
}

func (s *stubAIRepo) GetLastNDemandReadings(ctx context.Context, pointID, resourceID uint, n int) ([]entity.DemandReading, error) {
	return append([]entity.DemandReading(nil), s.readings...), nil
}

func (s *stubAIRepo) GetDemandReadingsByPoint(ctx context.Context, pointID uint, limit, offset int) ([]entity.DemandReading, int, error) {
	return append([]entity.DemandReading(nil), s.readings...), len(s.readings), nil
}

func (s *stubAIRepo) GetAllActivePointResourcePairs(ctx context.Context) ([]entity.PointResourcePair, error) {
	return append([]entity.PointResourcePair(nil), s.pairs...), nil
}

func (s *stubAIRepo) GetInventoryByResource(ctx context.Context, resourceID uint) ([]entity.WarehouseInventory, error) {
	return append([]entity.WarehouseInventory(nil), s.warehouseStocks...), nil
}

func (s *stubAIRepo) GetTotalStockForResource(ctx context.Context, resourceID uint) (float64, error) {
	return s.totalStock, nil
}

func (s *stubAIRepo) GetCustomerCoords(ctx context.Context, customerID uint) (lat, lon float64, err error) {
	coords := s.customerCoords[customerID]
	return coords[0], coords[1], nil
}

func (s *stubAIRepo) InsertPredictiveAlert(ctx context.Context, a entity.PredictiveAlert) (entity.PredictiveAlert, error) {
	a.ID = 101
	s.insertedAlert = &a
	s.alertByID = a
	return a, nil
}

func (s *stubAIRepo) GetAlertByID(ctx context.Context, id uint) (entity.PredictiveAlert, error) {
	return s.alertByID, nil
}

func (s *stubAIRepo) GetOpenAlertByPointAndResource(ctx context.Context, pointID, resourceID uint) (entity.PredictiveAlert, bool, error) {
	return s.openAlert, s.openAlertExists, nil
}

func (s *stubAIRepo) GetOpenAlerts(ctx context.Context, limit, offset int) ([]entity.PredictiveAlert, int, error) {
	return nil, 0, nil
}

func (s *stubAIRepo) GetAlertsByPoint(ctx context.Context, pointID uint) ([]entity.PredictiveAlert, error) {
	return nil, nil
}

func (s *stubAIRepo) UpdateAlertStatus(ctx context.Context, id uint, status entity.AlertStatus, proposalID *uint) error {
	s.updatedAlertID = id
	s.updatedAlertState = status
	if s.insertedAlert != nil {
		s.insertedAlert.Status = status
		s.insertedAlert.ProposalID = proposalID
		s.alertByID = *s.insertedAlert
	}
	return nil
}

func (s *stubAIRepo) InsertProposalWithTransfers(ctx context.Context, p entity.RebalancingProposal, transfers []entity.RebalancingTransfer) (entity.RebalancingProposal, error) {
	p.ID = 202
	p.Transfers = append([]entity.RebalancingTransfer(nil), transfers...)
	s.insertedProposal = &p
	s.insertedTransfers = append([]entity.RebalancingTransfer(nil), transfers...)
	s.proposalByID = p
	return p, nil
}

func (s *stubAIRepo) GetProposalByID(ctx context.Context, id uint) (entity.RebalancingProposal, error) {
	return s.proposalByID, nil
}

func (s *stubAIRepo) UpdateProposalStatus(ctx context.Context, id uint, status entity.ProposalStatus) error {
	s.updatedProposalID = id
	s.updatedProposal = status
	s.proposalByID.Status = status
	return nil
}

func testPredictionLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(io.Discard, nil))
}

func TestAnalyzeDetectsTrendingDemand(t *testing.T) {
	t.Parallel()

	base := time.Date(2026, 4, 1, 8, 0, 0, 0, time.UTC)
	analysis := Analyze([]DemandPoint{
		{Quantity: 5, RecordedAt: base},
		{Quantity: 5, RecordedAt: base.Add(1 * time.Hour)},
		{Quantity: 5, RecordedAt: base.Add(2 * time.Hour)},
		{Quantity: 50, RecordedAt: base.Add(3 * time.Hour)},
		{Quantity: 100, RecordedAt: base.Add(4 * time.Hour)},
	})

	if !analysis.IsTrending {
		t.Fatal("Analyze() IsTrending = false, want true")
	}
	if analysis.DivergenceRatio < divergenceThreshold {
		t.Fatalf("Analyze() divergence = %f, want >= %f", analysis.DivergenceRatio, divergenceThreshold)
	}
	if analysis.Confidence <= 0 {
		t.Fatalf("Analyze() confidence = %f, want > 0", analysis.Confidence)
	}
}

func TestAnalyzePairCreatesAlertAndProposalForTrendingDemand(t *testing.T) {
	t.Parallel()

	base := time.Date(2026, 4, 1, 8, 0, 0, 0, time.UTC)
	repo := &stubAIRepo{
		readings: []entity.DemandReading{
			{PointID: 10, ResourceID: 20, Quantity: 5, RecordedAt: base},
			{PointID: 10, ResourceID: 20, Quantity: 5, RecordedAt: base.Add(1 * time.Hour)},
			{PointID: 10, ResourceID: 20, Quantity: 5, RecordedAt: base.Add(2 * time.Hour)},
			{PointID: 10, ResourceID: 20, Quantity: 50, RecordedAt: base.Add(3 * time.Hour)},
			{PointID: 10, ResourceID: 20, Quantity: 100, RecordedAt: base.Add(4 * time.Hour)},
		},
		totalStock: 80,
		warehouseStocks: []entity.WarehouseInventory{
			{WarehouseID: 1, Quantity: 100, Lat: 50.45, Lon: 30.52},
			{WarehouseID: 2, Quantity: 150, Lat: 49.45, Lon: 30.52},
		},
		customerCoords: map[uint][2]float64{
			10: {50.45, 30.52},
		},
	}

	uc := New(repo, testPredictionLogger())
	if err := uc.analyzePair(context.Background(), 10, 20); err != nil {
		t.Fatalf("analyzePair() error = %v", err)
	}

	if repo.insertedAlert == nil {
		t.Fatal("analyzePair() did not insert an alert")
	}
	if repo.insertedAlert.Status != entity.AlertStatusOpen {
		t.Fatalf("inserted alert status = %q, want %q", repo.insertedAlert.Status, entity.AlertStatusOpen)
	}

	if repo.insertedProposal == nil {
		t.Fatal("analyzePair() did not insert a proposal")
	}
	if repo.insertedProposal.Status != entity.ProposalStatusPending {
		t.Fatalf("inserted proposal status = %q, want %q", repo.insertedProposal.Status, entity.ProposalStatusPending)
	}
	if len(repo.insertedTransfers) != 2 {
		t.Fatalf("transfer count = %d, want 2", len(repo.insertedTransfers))
	}
	if repo.insertedTransfers[0].FromWarehouseID != 2 {
		t.Fatalf("first transfer warehouse = %d, want 2", repo.insertedTransfers[0].FromWarehouseID)
	}

	totalTransferred := 0.0
	for _, transfer := range repo.insertedTransfers {
		totalTransferred += transfer.Quantity
	}
	if math.Abs(totalTransferred-135) > 0.001 {
		t.Fatalf("transferred quantity = %f, want 135", totalTransferred)
	}

	if repo.updatedAlertID != 101 {
		t.Fatalf("updated alert id = %d, want 101", repo.updatedAlertID)
	}
	if repo.alertByID.ProposalID == nil || *repo.alertByID.ProposalID != 202 {
		t.Fatalf("alert proposal id = %v, want 202", repo.alertByID.ProposalID)
	}
}

func TestDismissAlertAndApproveProposalTransitions(t *testing.T) {
	t.Parallel()

	t.Run("dismiss open alert", func(t *testing.T) {
		t.Parallel()

		repo := &stubAIRepo{
			alertByID: entity.PredictiveAlert{ID: 11, Status: entity.AlertStatusOpen},
		}
		uc := New(repo, testPredictionLogger())

		if err := uc.DismissAlert(context.Background(), 11); err != nil {
			t.Fatalf("DismissAlert() error = %v", err)
		}
		if repo.updatedAlertState != entity.AlertStatusDismissed {
			t.Fatalf("updated alert status = %q, want %q", repo.updatedAlertState, entity.AlertStatusDismissed)
		}
	})

	t.Run("reject dismiss for resolved alert", func(t *testing.T) {
		t.Parallel()

		repo := &stubAIRepo{
			alertByID: entity.PredictiveAlert{ID: 11, Status: entity.AlertStatusDismissed},
		}
		uc := New(repo, testPredictionLogger())

		err := uc.DismissAlert(context.Background(), 11)
		if !errors.Is(err, entity.ErrAlreadyResolved) {
			t.Fatalf("DismissAlert() error = %v, want %v", err, entity.ErrAlreadyResolved)
		}
	})

	t.Run("approve pending proposal", func(t *testing.T) {
		t.Parallel()

		repo := &stubAIRepo{
			proposalByID: entity.RebalancingProposal{ID: 21, Status: entity.ProposalStatusPending},
		}
		uc := New(repo, testPredictionLogger())

		proposal, err := uc.ApproveProposal(context.Background(), 21)
		if err != nil {
			t.Fatalf("ApproveProposal() error = %v", err)
		}
		if proposal.Status != entity.ProposalStatusApproved {
			t.Fatalf("proposal status = %q, want %q", proposal.Status, entity.ProposalStatusApproved)
		}
		if repo.updatedProposal != entity.ProposalStatusApproved {
			t.Fatalf("updated proposal status = %q, want %q", repo.updatedProposal, entity.ProposalStatusApproved)
		}
	})
}
