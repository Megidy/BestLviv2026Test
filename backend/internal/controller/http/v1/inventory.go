package v1

import (
	"context"
	"log/slog"
	"net/http"

	"github.com/Megidy/BestLviv2026Test/internal/dto"
	"github.com/Megidy/BestLviv2026Test/internal/dto/httpresponse"
	"github.com/Megidy/BestLviv2026Test/internal/entity"
	"github.com/labstack/echo/v5"
)

type inventoryUseCase interface {
	GetAllWithPagination(ctx context.Context, filter dto.GetAllInventoryFilter) (dto.GetAllInventoryResponse, error)
}
type InventoryController struct {
	logger           *slog.Logger
	inventoryUseCase inventoryUseCase
}

func NewInventoryController(logger *slog.Logger, useCase inventoryUseCase) *InventoryController {
	l := logger.With("controller", "inventory")
	return &InventoryController{
		logger:           l,
		inventoryUseCase: useCase,
	}
}

// GetAll godoc
// @Summary      Get all inventory units by location
// @Description  Retrieves a paginated list of inventory resources for a specific location. Supports filtering by resource name and category.
// @Tags         Inventory
// @Accept       json
// @Produce      json
// @Param        location_id         path      int     true   "Location ID"
// @Param        resource_name       query     string  false  "Filter by resource name (partial match)"
// @Param        resource_category   query     string  false  "Filter by resource category"
// @Param        page                query     int     true  "Number of records to return"
// @Param        pageSize            query     int     true  "Number of records to skip"
// @Success      200  {object}  httpresponse.Response{Data=dto.GetAllInventoryResponse} "Successfully retrieved inventory units"
// @Failure      400  {object}  httpresponse.Response{} "Bad Request - Invalid parameters or validation error"
// @Failure      500  {object}  httpresponse.Response{} "Internal Server Error"
// @Security 	 BearerAuth
// @Router       /v1/inventory/{location_id} [get]
func (r *InventoryController) GetAll(ctx *echo.Context) error {
	limit := ctx.Get(entity.LimitKey).(int)
	offset := ctx.Get(entity.OffsetKey).(int)
	l := r.logger.With("method", "get_all").With("limit", limit, "offset", offset)

	var filter dto.GetAllInventoryFilter

	err := ctx.Bind(&filter)
	if err != nil {
		l.Warn("failed to bind params", "error", err)
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, err.Error())
	}

	err = ctx.Validate(filter)
	if err != nil {
		l.Warn("failed to validate request", "error", err)
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, err.Error())
	}

	filter.Limit = limit
	filter.Offset = offset

	inventories, err := r.inventoryUseCase.GetAllWithPagination(ctx.Request().Context(), filter)
	if err != nil {
		l.Error("failed to get all with pagination", "error", err)
		return httpresponse.NewErrorResponse(ctx, err, "failed to get all with pagination")
	}

	return httpresponse.NewSuccessResponse(ctx, inventories, http.StatusOK)
}
