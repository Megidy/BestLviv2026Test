package v1

import (
	"context"
	"log/slog"
	"net/http"

	"github.com/Megidy/BestLviv2026Test/internal/dto/httpresponse"
	"github.com/Megidy/BestLviv2026Test/internal/entity"
	"github.com/labstack/echo/v5"
)

type mapUseCase interface {
	GetMapPoints(ctx context.Context) ([]entity.MapPoint, error)
}

type MapController struct {
	logger  *slog.Logger
	useCase mapUseCase
}

func NewMapController(logger *slog.Logger, uc mapUseCase) *MapController {
	return &MapController{logger: logger, useCase: uc}
}

// GetPoints godoc
// @Summary     Get all map points
// @Description Returns all warehouses and delivery points with status and coordinates
// @Tags        map
// @Produce     json
// @Security    BearerAuth
// @Success     200 {array}  entity.MapPoint
// @Failure     500 {object} httpresponse.ErrorResponse
// @Router      /map/points [get]
func (c *MapController) GetPoints(ctx *echo.Context) error {
	points, err := c.useCase.GetMapPoints(ctx.Request().Context())
	if err != nil {
		c.logger.Error("failed to get map points", "error", err)
		return httpresponse.NewErrorResponse(ctx, err, "failed to get map points")
	}
	if points == nil {
		points = []entity.MapPoint{}
	}
	return ctx.JSON(http.StatusOK, points)
}
