package v1

import (
	"context"
	"log/slog"
	"net/http"
	"strconv"
	"time"

	"github.com/Megidy/BestLviv2026Test/internal/dto/httprequest"
	"github.com/Megidy/BestLviv2026Test/internal/dto/httpresponse"
	"github.com/Megidy/BestLviv2026Test/internal/entity"
	"github.com/labstack/echo/v5"
)

type predictionUseCase interface {
	RecordDemand(ctx context.Context, d entity.DemandReading) (entity.DemandReading, error)
	GetDemandReadings(ctx context.Context, pointID uint, limit, offset int) ([]entity.DemandReading, int, error)
	GetOpenAlerts(ctx context.Context, limit, offset int) ([]entity.PredictiveAlert, int, error)
	GetAlertsByPoint(ctx context.Context, pointID uint) ([]entity.PredictiveAlert, error)
	DismissAlert(ctx context.Context, alertID uint) error
	GetProposal(ctx context.Context, proposalID uint) (entity.RebalancingProposal, error)
	ApproveProposal(ctx context.Context, proposalID uint) (entity.RebalancingProposal, error)
	DismissProposal(ctx context.Context, proposalID uint) error
	RunPredictions(ctx context.Context) error
}

type PredictionController struct {
	logger  *slog.Logger
	useCase predictionUseCase
}

func NewPredictionController(logger *slog.Logger, uc predictionUseCase) *PredictionController {
	return &PredictionController{
		logger:  logger.With("controller", "prediction"),
		useCase: uc,
	}
}

// RecordDemand godoc
// @Summary      Record a demand reading
// @Description  Stores a new demand data point for a delivery point + resource pair. Triggers background analysis.
// @Tags         AI
// @Accept       json
// @Produce      json
// @Param        body body httprequest.RecordDemand true "Demand reading"
// @Success      201  {object}  httpresponse.Response{Data=entity.DemandReading}
// @Failure      400  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/demand-readings [post]
func (c *PredictionController) RecordDemand(ctx *echo.Context) error {
	var req httprequest.RecordDemand
	if err := ctx.Bind(&req); err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, err.Error())
	}
	if err := ctx.Validate(req); err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, err.Error())
	}

	reading := entity.DemandReading{
		PointID:    req.PointID,
		ResourceID: req.ResourceID,
		Quantity:   req.Quantity,
		Source:     req.Source,
	}
	if reading.Source == "" {
		reading.Source = entity.DemandSourceManual
	}
	if req.RecordedAt != nil {
		reading.RecordedAt = *req.RecordedAt
	} else {
		reading.RecordedAt = time.Now()
	}

	c.logger.Info("recording demand", "point_id", reading.PointID, "resource_id", reading.ResourceID, "quantity", reading.Quantity, "source", reading.Source)
	result, err := c.useCase.RecordDemand(ctx.Request().Context(), reading)
	if err != nil {
		c.logger.Error("record demand failed", "point_id", reading.PointID, "resource_id", reading.ResourceID, "error", err)
		return httpresponse.NewErrorResponse(ctx, err)
	}
	c.logger.Info("demand recorded", "id", result.ID, "point_id", result.PointID, "resource_id", result.ResourceID)
	return httpresponse.NewSuccessResponse(ctx, result, http.StatusCreated)
}

// GetDemandReadings godoc
// @Summary      Get demand readings for a delivery point
// @Tags         AI
// @Produce      json
// @Param        point_id path  int true  "Customer/delivery point ID"
// @Param        page     query int false "Page number"
// @Param        pageSize query int false "Page size"
// @Success      200  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/demand-readings/{point_id} [get]
func (c *PredictionController) GetDemandReadings(ctx *echo.Context) error {
	pointID, err := parseUintParam(ctx, "point_id")
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid point_id")
	}
	limit := ctx.Get(entity.LimitKey)
	offset := ctx.Get(entity.OffsetKey)
	l, _ := limit.(int)
	o, _ := offset.(int)
	if l == 0 {
		l = 20
	}

	c.logger.Info("fetching demand readings", "point_id", pointID, "limit", l, "offset", o)
	readings, total, err := c.useCase.GetDemandReadings(ctx.Request().Context(), pointID, l, o)
	if err != nil {
		c.logger.Error("get demand readings failed", "point_id", pointID, "error", err)
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, map[string]any{"readings": readings, "total": total}, http.StatusOK)
}

// GetOpenAlerts godoc
// @Summary      List open predictive alerts
// @Tags         AI
// @Produce      json
// @Param        page     query int false "Page"
// @Param        pageSize query int false "Page size"
// @Success      200  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/predictive-alerts [get]
func (c *PredictionController) GetOpenAlerts(ctx *echo.Context) error {
	limit := ctx.Get(entity.LimitKey)
	offset := ctx.Get(entity.OffsetKey)
	l, _ := limit.(int)
	o, _ := offset.(int)
	if l == 0 {
		l = 20
	}

	c.logger.Info("fetching open alerts", "limit", l, "offset", o)
	alerts, total, err := c.useCase.GetOpenAlerts(ctx.Request().Context(), l, o)
	if err != nil {
		c.logger.Error("get open alerts failed", "error", err)
		return httpresponse.NewErrorResponse(ctx, err)
	}
	c.logger.Info("open alerts fetched", "count", len(alerts), "total", total)
	return httpresponse.NewSuccessResponse(ctx, map[string]any{"alerts": alerts, "total": total}, http.StatusOK)
}

// GetAlertsByPoint godoc
// @Summary      Get all alerts for a delivery point
// @Tags         AI
// @Produce      json
// @Param        point_id path int true "Delivery point ID"
// @Success      200  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/predictive-alerts/{point_id} [get]
func (c *PredictionController) GetAlertsByPoint(ctx *echo.Context) error {
	pointID, err := parseUintParam(ctx, "point_id")
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid point_id")
	}

	c.logger.Info("fetching alerts by point", "point_id", pointID)
	alerts, err := c.useCase.GetAlertsByPoint(ctx.Request().Context(), pointID)
	if err != nil {
		c.logger.Error("get alerts by point failed", "point_id", pointID, "error", err)
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, alerts, http.StatusOK)
}

// DismissAlert godoc
// @Summary      Dismiss a predictive alert
// @Tags         AI
// @Produce      json
// @Param        alert_id path int true "Alert ID"
// @Success      200  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/predictive-alerts/{alert_id}/dismiss [post]
func (c *PredictionController) DismissAlert(ctx *echo.Context) error {
	alertID, err := parseUintParam(ctx, "alert_id")
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid alert_id")
	}
	c.logger.Info("dismissing alert", "alert_id", alertID)
	if err := c.useCase.DismissAlert(ctx.Request().Context(), alertID); err != nil {
		c.logger.Error("dismiss alert failed", "alert_id", alertID, "error", err)
		return httpresponse.NewErrorResponse(ctx, err)
	}
	c.logger.Info("alert dismissed", "alert_id", alertID)
	return httpresponse.NewSuccessResponse(ctx, nil, http.StatusOK)
}

// GetProposal godoc
// @Summary      Get a rebalancing proposal with its transfers
// @Tags         AI
// @Produce      json
// @Param        proposal_id path int true "Proposal ID"
// @Success      200  {object}  httpresponse.Response{Data=entity.RebalancingProposal}
// @Security     BearerAuth
// @Router       /v1/rebalancing-proposals/{proposal_id} [get]
func (c *PredictionController) GetProposal(ctx *echo.Context) error {
	id, err := parseUintParam(ctx, "proposal_id")
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid proposal_id")
	}
	c.logger.Info("fetching proposal", "proposal_id", id)
	proposal, err := c.useCase.GetProposal(ctx.Request().Context(), id)
	if err != nil {
		c.logger.Error("get proposal failed", "proposal_id", id, "error", err)
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, proposal, http.StatusOK)
}

// ApproveProposal godoc
// @Summary      Approve a rebalancing proposal (one-tap confirm)
// @Tags         AI
// @Produce      json
// @Param        proposal_id path int true "Proposal ID"
// @Success      200  {object}  httpresponse.Response{Data=entity.RebalancingProposal}
// @Security     BearerAuth
// @Router       /v1/rebalancing-proposals/{proposal_id}/approve [post]
func (c *PredictionController) ApproveProposal(ctx *echo.Context) error {
	id, err := parseUintParam(ctx, "proposal_id")
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid proposal_id")
	}
	c.logger.Info("approving proposal", "proposal_id", id)
	proposal, err := c.useCase.ApproveProposal(ctx.Request().Context(), id)
	if err != nil {
		c.logger.Error("approve proposal failed", "proposal_id", id, "error", err)
		return httpresponse.NewErrorResponse(ctx, err)
	}
	c.logger.Info("proposal approved", "proposal_id", id)
	return httpresponse.NewSuccessResponse(ctx, proposal, http.StatusOK)
}

// DismissProposal godoc
// @Summary      Dismiss a rebalancing proposal
// @Tags         AI
// @Produce      json
// @Param        proposal_id path int true "Proposal ID"
// @Success      200  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/rebalancing-proposals/{proposal_id}/dismiss [post]
func (c *PredictionController) DismissProposal(ctx *echo.Context) error {
	id, err := parseUintParam(ctx, "proposal_id")
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid proposal_id")
	}
	c.logger.Info("dismissing proposal", "proposal_id", id)
	if err := c.useCase.DismissProposal(ctx.Request().Context(), id); err != nil {
		c.logger.Error("dismiss proposal failed", "proposal_id", id, "error", err)
		return httpresponse.NewErrorResponse(ctx, err)
	}
	c.logger.Info("proposal dismissed", "proposal_id", id)
	return httpresponse.NewSuccessResponse(ctx, nil, http.StatusOK)
}

// TriggerPredictions godoc
// @Summary      Manually trigger the prediction run (admin)
// @Tags         AI
// @Produce      json
// @Success      202  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/ai/run [post]
func (c *PredictionController) TriggerPredictions(ctx *echo.Context) error {
	go func() {
		bgCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		if err := c.useCase.RunPredictions(bgCtx); err != nil {
			c.logger.Error("manual prediction run failed", "error", err)
		}
	}()
	return httpresponse.NewSuccessResponse(ctx, map[string]string{"status": "prediction run started"}, http.StatusAccepted)
}

func parseUintParam(ctx *echo.Context, name string) (uint, error) {
	v, err := strconv.ParseUint(ctx.Param(name), 10, 64)
	return uint(v), err
}
