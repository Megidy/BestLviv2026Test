package v1

import (
	"context"
	"log/slog"
	"net/http"
	"strconv"

	"github.com/Megidy/BestLviv2026Test/internal/dto"
	"github.com/Megidy/BestLviv2026Test/internal/dto/httprequest"
	"github.com/Megidy/BestLviv2026Test/internal/dto/httpresponse"
	"github.com/Megidy/BestLviv2026Test/internal/entity"
	"github.com/labstack/echo/v5"
)

type deliveryUseCase interface {
	CreateRequest(ctx context.Context, actor dto.UserClaims, req httprequest.CreateDeliveryRequest) (entity.DeliveryRequest, error)
	GetRequests(ctx context.Context, filter dto.DeliveryRequestFilter) ([]entity.DeliveryRequest, int, error)
	GetRequestByID(ctx context.Context, id uint) (entity.DeliveryRequest, error)
	CancelRequest(ctx context.Context, actor dto.UserClaims, requestID uint) error
	DeliverRequest(ctx context.Context, actor dto.UserClaims, requestID uint) error
	EscalateRequest(ctx context.Context, actor dto.UserClaims, requestID uint) (entity.DeliveryRequest, error)
	UpdateItemQuantity(ctx context.Context, actor dto.UserClaims, requestID, resourceID uint, newQty float64) error
	AllocatePending(ctx context.Context, actor dto.UserClaims) (int, error)
	ApproveAllocation(ctx context.Context, actor dto.UserClaims, allocationID uint) (entity.Allocation, error)
	RejectAllocation(ctx context.Context, actor dto.UserClaims, allocationID uint, reason string) error
	ApproveAllAllocations(ctx context.Context, actor dto.UserClaims, requestID uint) error
	DispatchAllocation(ctx context.Context, actor dto.UserClaims, allocationID uint) (entity.Allocation, error)
	GetAllocations(ctx context.Context, filter dto.AllocationFilter) ([]entity.Allocation, int, error)
	FindNearestStock(ctx context.Context, resourceID, customerID uint, needed float64) ([]dto.NearestStockResult, error)
	GetAuditLog(ctx context.Context, filter dto.AuditFilter) ([]entity.AuditEntry, int, error)
}

type DeliveryController struct {
	logger  *slog.Logger
	useCase deliveryUseCase
}

func NewDeliveryController(logger *slog.Logger, uc deliveryUseCase) *DeliveryController {
	return &DeliveryController{
		logger:  logger.With("controller", "delivery"),
		useCase: uc,
	}
}

// CreateRequest godoc
// @Summary      Create a delivery request
// @Description  WORKER creates a multi-item delivery request. Urgent requests are auto-allocated immediately.
// @Tags         Delivery
// @Accept       json
// @Produce      json
// @Param        body body httprequest.CreateDeliveryRequest true "Request body"
// @Success      201  {object}  httpresponse.Response{Data=entity.DeliveryRequest}
// @Failure      400  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/delivery-requests [post]
func (c *DeliveryController) CreateRequest(ctx *echo.Context) error {
	l := c.logger.With("method", "create_request")
	actor := ctx.Get(entity.UserKey).(dto.UserClaims)

	var req httprequest.CreateDeliveryRequest
	if err := ctx.Bind(&req); err != nil {
		l.Warn("failed to bind request", "error", err)
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, err.Error())
	}
	if err := ctx.Validate(req); err != nil {
		l.Warn("failed to validate request", "error", err)
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, err.Error())
	}

	result, err := c.useCase.CreateRequest(ctx.Request().Context(), actor, req)
	if err != nil {
		l.Error("create request failed", "error", err)
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, result, http.StatusCreated)
}

// GetRequests godoc
// @Summary      List delivery requests
// @Tags         Delivery
// @Produce      json
// @Param        status   query string false "Filter by status"
// @Param        priority query string false "Filter by priority"
// @Param        page     query int    false "Page"
// @Param        pageSize query int    false "Page size"
// @Success      200  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/delivery-requests [get]
func (c *DeliveryController) GetRequests(ctx *echo.Context) error {
	l := c.logger.With("method", "create_request")

	actor := ctx.Get(entity.UserKey).(dto.UserClaims)

	var filter dto.DeliveryRequestFilter
	if err := ctx.Bind(&filter); err != nil {
		l.Warn("failed to bind request", "error", err)
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, err.Error())
	}

	// WORKERs only see their own requests
	if actor.Role == entity.UserRoleWorker {
		filter.UserID = uint(actor.UserID)
	}

	limit, _ := ctx.Get(entity.LimitKey).(int)
	offset, _ := ctx.Get(entity.OffsetKey).(int)

	filter.Limit = limit
	filter.Offset = offset

	requests, total, err := c.useCase.GetRequests(ctx.Request().Context(), filter)
	if err != nil {
		l.Error("failed to get requests", "error", err)
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, map[string]any{"requests": requests, "total": total}, http.StatusOK)
}

// GetRequestByID godoc
// @Summary      Get a delivery request with items and allocations
// @Tags         Delivery
// @Produce      json
// @Param        id path int true "Request ID"
// @Success      200  {object}  httpresponse.Response{Data=entity.DeliveryRequest}
// @Security     BearerAuth
// @Router       /v1/delivery-requests/{id} [get]
func (c *DeliveryController) GetRequestByID(ctx *echo.Context) error {
	id, err := parseUintParam(ctx, "id")
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid id")
	}
	req, err := c.useCase.GetRequestByID(ctx.Request().Context(), id)
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, req, http.StatusOK)
}

// CancelRequest godoc
// @Summary      Cancel a delivery request
// @Tags         Delivery
// @Produce      json
// @Param        id path int true "Request ID"
// @Success      200  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/delivery-requests/{id}/cancel [post]
func (c *DeliveryController) CancelRequest(ctx *echo.Context) error {
	actor := ctx.Get(entity.UserKey).(dto.UserClaims)
	id, err := parseUintParam(ctx, "id")
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid id")
	}
	if err := c.useCase.CancelRequest(ctx.Request().Context(), actor, id); err != nil {
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, nil, http.StatusOK)
}

// DeliverRequest godoc
// @Summary      Confirm delivery of a request
// @Tags         Delivery
// @Produce      json
// @Param        id path int true "Request ID"
// @Success      200  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/delivery-requests/{id}/deliver [post]
func (c *DeliveryController) DeliverRequest(ctx *echo.Context) error {
	actor := ctx.Get(entity.UserKey).(dto.UserClaims)
	id, err := parseUintParam(ctx, "id")
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid id")
	}
	if err := c.useCase.DeliverRequest(ctx.Request().Context(), actor, id); err != nil {
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, nil, http.StatusOK)
}

// EscalateRequest godoc
// @Summary      Escalate request priority one level up
// @Tags         Delivery
// @Produce      json
// @Param        id path int true "Request ID"
// @Success      200  {object}  httpresponse.Response{Data=entity.DeliveryRequest}
// @Security     BearerAuth
// @Router       /v1/delivery-requests/{id}/escalate [post]
func (c *DeliveryController) EscalateRequest(ctx *echo.Context) error {
	actor := ctx.Get(entity.UserKey).(dto.UserClaims)
	id, err := parseUintParam(ctx, "id")
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid id")
	}
	req, err := c.useCase.EscalateRequest(ctx.Request().Context(), actor, id)
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, req, http.StatusOK)
}

// UpdateItemQuantity godoc
// @Summary      Update quantity for one item in a pending request
// @Tags         Delivery
// @Accept       json
// @Produce      json
// @Param        id   path int                                     true "Request ID"
// @Param        body body httprequest.UpdateItemQuantityRequest   true "Body"
// @Success      200  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/delivery-requests/{id}/items [patch]
func (c *DeliveryController) UpdateItemQuantity(ctx *echo.Context) error {
	actor := ctx.Get(entity.UserKey).(dto.UserClaims)
	id, err := parseUintParam(ctx, "id")
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid id")
	}

	var req httprequest.UpdateItemQuantityRequest
	if err := ctx.Bind(&req); err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, err.Error())
	}
	if err := ctx.Validate(req); err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, err.Error())
	}

	if err := c.useCase.UpdateItemQuantity(ctx.Request().Context(), actor, id, req.ResourceID, req.Quantity); err != nil {
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, nil, http.StatusOK)
}

// AllocatePending godoc
// @Summary      Run allocation algorithm on all pending requests (DISPATCHER)
// @Tags         Delivery
// @Produce      json
// @Success      200  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/delivery-requests/allocate [post]
func (c *DeliveryController) AllocatePending(ctx *echo.Context) error {
	actor := ctx.Get(entity.UserKey).(dto.UserClaims)
	if actor.Role == entity.UserRoleWorker {
		return httpresponse.NewErrorResponse(ctx, entity.ErrForbidden)
	}
	count, err := c.useCase.AllocatePending(ctx.Request().Context(), actor)
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, map[string]int{"allocated": count}, http.StatusOK)
}

// ApproveAllAllocations godoc
// @Summary      Approve all planned allocations for a request (DISPATCHER)
// @Tags         Delivery
// @Produce      json
// @Param        id path int true "Request ID"
// @Success      200  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/delivery-requests/{id}/approve-all [post]
func (c *DeliveryController) ApproveAllAllocations(ctx *echo.Context) error {
	actor := ctx.Get(entity.UserKey).(dto.UserClaims)
	if actor.Role == entity.UserRoleWorker {
		return httpresponse.NewErrorResponse(ctx, entity.ErrForbidden)
	}
	id, err := parseUintParam(ctx, "id")
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid id")
	}
	if err := c.useCase.ApproveAllAllocations(ctx.Request().Context(), actor, id); err != nil {
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, nil, http.StatusOK)
}

// --- Allocations ---

// GetAllocations godoc
// @Summary      List allocations
// @Tags         Delivery
// @Produce      json
// @Param        status     query string false "Filter by status"
// @Param        request_id query int    false "Filter by request"
// @Param        page                query     int     true  "Number of records to return"
// @Param        pageSize            query     int     true  "Number of records to skip"
// @Success      200  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/allocations [get]
func (c *DeliveryController) GetAllocations(ctx *echo.Context) error {
	var filter dto.AllocationFilter
	if err := ctx.Bind(&filter); err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, err.Error())
	}
	limit, _ := ctx.Get(entity.LimitKey).(int)
	offset, _ := ctx.Get(entity.OffsetKey).(int)

	filter.Limit = limit
	filter.Offset = offset

	allocs, total, err := c.useCase.GetAllocations(ctx.Request().Context(), filter)
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, map[string]any{"allocations": allocs, "total": total}, http.StatusOK)
}

// ApproveAllocation godoc
// @Summary      Approve a planned allocation (DISPATCHER)
// @Tags         Delivery
// @Produce      json
// @Param        id path int true "Allocation ID"
// @Success      200  {object}  httpresponse.Response{Data=entity.Allocation}
// @Security     BearerAuth
// @Router       /v1/allocations/{id}/approve [post]
func (c *DeliveryController) ApproveAllocation(ctx *echo.Context) error {
	actor := ctx.Get(entity.UserKey).(dto.UserClaims)
	if actor.Role == entity.UserRoleWorker {
		return httpresponse.NewErrorResponse(ctx, entity.ErrForbidden)
	}
	id, err := parseUintParam(ctx, "id")
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid id")
	}
	alloc, err := c.useCase.ApproveAllocation(ctx.Request().Context(), actor, id)
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, alloc, http.StatusOK)
}

// RejectAllocation godoc
// @Summary      Reject an allocation (DISPATCHER)
// @Tags         Delivery
// @Accept       json
// @Produce      json
// @Param        id   path int                                  true "Allocation ID"
// @Param        body body httprequest.RejectAllocationRequest  true "Body"
// @Success      200  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/allocations/{id}/reject [post]
func (c *DeliveryController) RejectAllocation(ctx *echo.Context) error {
	actor := ctx.Get(entity.UserKey).(dto.UserClaims)
	if actor.Role == entity.UserRoleWorker {
		return httpresponse.NewErrorResponse(ctx, entity.ErrForbidden)
	}
	id, err := parseUintParam(ctx, "id")
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid id")
	}
	var req httprequest.RejectAllocationRequest
	if err := ctx.Bind(&req); err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, err.Error())
	}
	if err := ctx.Validate(req); err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, err.Error())
	}
	if err := c.useCase.RejectAllocation(ctx.Request().Context(), actor, id, req.Reason); err != nil {
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, nil, http.StatusOK)
}

// DispatchAllocation godoc
// @Summary      Mark an allocation as dispatched (WORKER at source warehouse)
// @Tags         Delivery
// @Produce      json
// @Param        id path int true "Allocation ID"
// @Success      200  {object}  httpresponse.Response{Data=entity.Allocation}
// @Security     BearerAuth
// @Router       /v1/allocations/{id}/dispatch [post]
func (c *DeliveryController) DispatchAllocation(ctx *echo.Context) error {
	actor := ctx.Get(entity.UserKey).(dto.UserClaims)
	id, err := parseUintParam(ctx, "id")
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid id")
	}
	alloc, err := c.useCase.DispatchAllocation(ctx.Request().Context(), actor, id)
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, alloc, http.StatusOK)
}

// --- Nearest Stock ---

// FindNearestStock godoc
// @Summary      Find nearest warehouses with surplus stock for a resource
// @Tags         Delivery
// @Produce      json
// @Param        resource_id query int     true  "Resource ID"
// @Param        point_id    query int     true  "Destination customer ID"
// @Param        quantity    query number  false "Required quantity (optional)"
// @Success      200  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/stock/nearest [get]
func (c *DeliveryController) FindNearestStock(ctx *echo.Context) error {
	resourceID, err := queryUint(ctx, "resource_id")
	if err != nil || resourceID == 0 {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid resource_id")
	}
	pointID, err := queryUint(ctx, "point_id")
	if err != nil || pointID == 0 {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, "invalid point_id")
	}

	var needed float64
	if q := ctx.QueryParam("quantity"); q != "" {
		needed, _ = strconv.ParseFloat(q, 64)
	}

	result, err := c.useCase.FindNearestStock(ctx.Request().Context(), resourceID, pointID, needed)
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, result, http.StatusOK)
}

// --- Audit Log ---

// GetAuditLog godoc
// @Summary      Get audit log (ADMIN only)
// @Tags         Admin
// @Produce      json
// @Param        actor_id    query int    false "Filter by actor"
// @Param        action      query string false "Filter by action"
// @Param        entity_type query string false "Filter by entity type"
// @Param        page                query     int     true  "Number of records to return"
// @Param        pageSize            query     int     true  "Number of records to skip"
// @Success      200  {object}  httpresponse.Response{}
// @Security     BearerAuth
// @Router       /v1/audit-log [get]
func (c *DeliveryController) GetAuditLog(ctx *echo.Context) error {
	actor := ctx.Get(entity.UserKey).(dto.UserClaims)
	if actor.Role != entity.UserRoleAdmin {
		return httpresponse.NewErrorResponse(ctx, entity.ErrForbidden)
	}

	var filter dto.AuditFilter
	if err := ctx.Bind(&filter); err != nil {
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, err.Error())
	}
	limit, _ := ctx.Get(entity.LimitKey).(int)
	offset, _ := ctx.Get(entity.OffsetKey).(int)
	filter.Limit = limit
	filter.Offset = offset

	entries, total, err := c.useCase.GetAuditLog(ctx.Request().Context(), filter)
	if err != nil {
		return httpresponse.NewErrorResponse(ctx, err)
	}
	return httpresponse.NewSuccessResponse(ctx, map[string]any{"entries": entries, "total": total}, http.StatusOK)
}

func queryUint(ctx *echo.Context, name string) (uint, error) {
	s := ctx.QueryParam(name)
	if s == "" {
		return 0, nil
	}
	v, err := strconv.ParseUint(s, 10, 64)
	return uint(v), err
}
