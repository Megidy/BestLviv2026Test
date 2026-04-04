package deliveryrequest

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"math"
	"sort"
	"time"

	"github.com/Megidy/BestLviv2026Test/internal/dto"
	"github.com/Megidy/BestLviv2026Test/internal/dto/httprequest"
	"github.com/Megidy/BestLviv2026Test/internal/entity"
)

const (
	safetyStockRatio = 0.20 // 20% of stock kept as safety minimum
	avgSpeedKmH      = 60.0
	earthRadiusKm    = 6371.0
	maxNearestStock  = 5
)

type deliveryRepo interface {
	InsertRequest(ctx context.Context, req entity.DeliveryRequest) (entity.DeliveryRequest, error)
	InsertRequestItems(ctx context.Context, requestID uint, items []entity.DeliveryRequestItem) ([]entity.DeliveryRequestItem, error)
	GetRequestByID(ctx context.Context, id uint) (entity.DeliveryRequest, error)
	GetRequests(ctx context.Context, filter dto.DeliveryRequestFilter) ([]entity.DeliveryRequest, int, error)
	GetRequestItems(ctx context.Context, requestID uint) ([]entity.DeliveryRequestItem, error)
	GetPendingRequests(ctx context.Context) ([]entity.DeliveryRequest, error)
	UpdateRequestStatus(ctx context.Context, id uint, status entity.DeliveryStatus) error
	UpdateRequestPriority(ctx context.Context, id uint, priority entity.DeliveryPriority) error
	UpdateRequestItemQuantity(ctx context.Context, requestID, resourceID uint, quantity float64) error

	InsertAllocation(ctx context.Context, a entity.Allocation) (entity.Allocation, error)
	GetAllocationByID(ctx context.Context, id uint) (entity.Allocation, error)
	GetAllocationsByRequest(ctx context.Context, requestID uint) ([]entity.Allocation, error)
	GetAllocations(ctx context.Context, filter dto.AllocationFilter) ([]entity.Allocation, int, error)
	UpdateAllocationStatus(ctx context.Context, id uint, status entity.AllocationStatus, dispatchedAt *time.Time) error
	AllAllocationsForRequestHaveStatus(ctx context.Context, requestID uint, status entity.AllocationStatus) (bool, error)
	HasAnyAllocationWithStatus(ctx context.Context, requestID uint, statuses ...entity.AllocationStatus) (bool, error)

	GetInventoryByResource(ctx context.Context, resourceID uint) ([]entity.WarehouseInventory, error)
	GetWarehouseInventory(ctx context.Context, warehouseID, resourceID uint) (float64, error)
	AdjustInventory(ctx context.Context, warehouseID, resourceID uint, delta float64) error
	GetCustomerCoords(ctx context.Context, customerID uint) (lat, lon float64, err error)
	GetAllWarehousesWithResource(ctx context.Context, resourceID uint) ([]entity.WarehouseInventory, error)
}

type auditRepo interface {
	Insert(ctx context.Context, entry entity.AuditEntry) error
	GetAll(ctx context.Context, filter dto.AuditFilter) ([]entity.AuditEntry, int, error)
}

// UseCase implements all delivery module business logic.
type UseCase struct {
	repo      deliveryRepo
	auditRepo auditRepo
	logger    *slog.Logger
}

func New(repo deliveryRepo, auditRepo auditRepo, logger *slog.Logger) *UseCase {
	return &UseCase{repo: repo, auditRepo: auditRepo, logger: logger}
}

// --- Create ---

// CreateRequest creates a new delivery request with its items.
// If priority is urgent, immediately attempts auto-allocation.
func (u *UseCase) CreateRequest(ctx context.Context, actor dto.UserClaims, req httprequest.CreateDeliveryRequest) (entity.DeliveryRequest, error) {
	if req.Priority == entity.PriorityUrgent && req.ArriveTill == nil {
		return entity.DeliveryRequest{}, fmt.Errorf("%w: arrive_till is required for urgent requests", entity.ErrBadRequest)
	}
	if req.ArriveTill != nil && req.ArriveTill.Before(time.Now()) {
		return entity.DeliveryRequest{}, fmt.Errorf("%w: arrive_till must be in the future", entity.ErrBadRequest)
	}

	// Use first item as the primary resource on the request row (schema requires resource_id NOT NULL)
	firstItem := req.Items[0]

	dr := entity.DeliveryRequest{
		DestinationID: req.DestinationID,
		ResourceID:    firstItem.ResourceID,
		UserID:        uint(actor.UserID),
		Quantity:      firstItem.Quantity,
		Priority:      req.Priority,
		Status:        entity.StatusPending,
		ArriveTill:    req.ArriveTill,
	}

	created, err := u.repo.InsertRequest(ctx, dr)
	if err != nil {
		return entity.DeliveryRequest{}, fmt.Errorf("insert request: %w", err)
	}

	// Insert all items
	items := make([]entity.DeliveryRequestItem, len(req.Items))
	for i, it := range req.Items {
		items[i] = entity.DeliveryRequestItem{
			ResourceID: it.ResourceID,
			Quantity:   it.Quantity,
		}
	}
	created.Items, err = u.repo.InsertRequestItems(ctx, created.ID, items)
	if err != nil {
		return entity.DeliveryRequest{}, fmt.Errorf("insert items: %w", err)
	}

	u.audit(ctx, actor, entity.AuditDeliveryRequestCreated, "delivery_request", created.ID, nil, created, "")

	// Urgent: skip the queue and allocate immediately
	if req.Priority == entity.PriorityUrgent {
		if err := u.autoAllocate(ctx, actor, &created, entity.AllocationStatusApproved); err != nil {
			u.logger.Warn("urgent auto-allocation failed", "request_id", created.ID, "error", err)
			// Don't fail the request — dispatcher will handle manually
		} else {
			u.audit(ctx, actor, entity.AuditUrgentRequestProcessed, "delivery_request", created.ID, nil, created, "")
		}
	}

	return created, nil
}

// --- Read ---

func (u *UseCase) GetRequests(ctx context.Context, filter dto.DeliveryRequestFilter) ([]entity.DeliveryRequest, int, error) {
	if filter.Limit == 0 {
		filter.Limit = 20
	}
	return u.repo.GetRequests(ctx, filter)
}

func (u *UseCase) GetRequestByID(ctx context.Context, id uint) (entity.DeliveryRequest, error) {
	req, err := u.repo.GetRequestByID(ctx, id)
	if err != nil {
		return entity.DeliveryRequest{}, err
	}
	req.Items, _ = u.repo.GetRequestItems(ctx, id)
	req.Allocations, _ = u.repo.GetAllocationsByRequest(ctx, id)
	return req, nil
}

// --- Mutate status ---

// CancelRequest cancels a delivery request. WORKERs can only cancel their own PENDING requests.
func (u *UseCase) CancelRequest(ctx context.Context, actor dto.UserClaims, requestID uint) error {
	req, err := u.repo.GetRequestByID(ctx, requestID)
	if err != nil {
		return err
	}

	// Role check: WORKER can only cancel their own
	if actor.Role == entity.UserRoleWorker && req.UserID != uint(actor.UserID) {
		return entity.ErrForbidden
	}
	// WORKER can only cancel PENDING; DISPATCHER can cancel PENDING or ALLOCATED
	if actor.Role == entity.UserRoleWorker && req.Status != entity.StatusPending {
		return fmt.Errorf("%w: workers can only cancel pending requests", entity.ErrInvalidStatusTransition)
	}
	if req.Status == entity.StatusInTransit || req.Status == entity.StatusDelivered || req.Status == entity.StatusCancelled {
		return fmt.Errorf("%w: cannot cancel a request in status %s", entity.ErrInvalidStatusTransition, req.Status)
	}

	// Release inventory if already allocated
	if req.Status == entity.StatusAllocated {
		if err := u.releaseAllocations(ctx, requestID); err != nil {
			return err
		}
	}

	if err := u.repo.UpdateRequestStatus(ctx, requestID, entity.StatusCancelled); err != nil {
		return err
	}
	u.audit(ctx, actor, entity.AuditDeliveryRequestCancelled, "delivery_request", requestID, req, nil, "")
	return nil
}

// DeliverRequest marks the full request as delivered.
func (u *UseCase) DeliverRequest(ctx context.Context, actor dto.UserClaims, requestID uint) error {
	req, err := u.repo.GetRequestByID(ctx, requestID)
	if err != nil {
		return err
	}
	if req.Status != entity.StatusInTransit {
		return fmt.Errorf("%w: request must be in_transit to confirm delivery", entity.ErrInvalidStatusTransition)
	}

	allocs, err := u.repo.GetAllocationsByRequest(ctx, requestID)
	if err != nil {
		return err
	}
	for _, a := range allocs {
		if a.Status == entity.AllocationStatusInTransit {
			if err := u.repo.UpdateAllocationStatus(ctx, a.ID, entity.AllocationStatusDelivered, a.DispatchedAt); err != nil {
				return err
			}
		}
	}

	if err := u.repo.UpdateRequestStatus(ctx, requestID, entity.StatusDelivered); err != nil {
		return err
	}
	u.audit(ctx, actor, entity.AuditDeliveryConfirmed, "delivery_request", requestID, req.Status, entity.StatusDelivered, "")
	return nil
}

// EscalateRequest bumps a request's priority one level up.
func (u *UseCase) EscalateRequest(ctx context.Context, actor dto.UserClaims, requestID uint) (entity.DeliveryRequest, error) {
	req, err := u.repo.GetRequestByID(ctx, requestID)
	if err != nil {
		return entity.DeliveryRequest{}, err
	}

	// WORKER can only escalate their own
	if actor.Role == entity.UserRoleWorker && req.UserID != uint(actor.UserID) {
		return entity.DeliveryRequest{}, entity.ErrForbidden
	}

	oldPriority := req.Priority
	newPriority, ok := escalatePriority(req.Priority)
	if !ok {
		return entity.DeliveryRequest{}, fmt.Errorf("%w: request is already at maximum priority", entity.ErrInvalidStatusTransition)
	}

	if err := u.repo.UpdateRequestPriority(ctx, requestID, newPriority); err != nil {
		return entity.DeliveryRequest{}, err
	}
	req.Priority = newPriority

	u.audit(ctx, actor, entity.AuditPriorityEscalated, "delivery_request", requestID, oldPriority, newPriority, "")

	// If now urgent and still pending, attempt immediate allocation
	if newPriority == entity.PriorityUrgent && req.Status == entity.StatusPending {
		if err := u.autoAllocate(ctx, actor, &req, entity.AllocationStatusApproved); err != nil {
			u.logger.Warn("post-escalation auto-allocation failed", "request_id", requestID, "error", err)
		}
	}

	return req, nil
}

// UpdateItemQuantity changes the quantity of one item and recalculates if needed.
func (u *UseCase) UpdateItemQuantity(ctx context.Context, actor dto.UserClaims, requestID, resourceID uint, newQty float64) error {
	req, err := u.repo.GetRequestByID(ctx, requestID)
	if err != nil {
		return err
	}
	if actor.Role == entity.UserRoleWorker && req.UserID != uint(actor.UserID) {
		return entity.ErrForbidden
	}
	if req.Status != entity.StatusPending {
		return fmt.Errorf("%w: can only update items on pending requests", entity.ErrInvalidStatusTransition)
	}

	items, err := u.repo.GetRequestItems(ctx, requestID)
	if err != nil {
		return err
	}
	var oldQty float64
	for _, it := range items {
		if it.ResourceID == resourceID {
			oldQty = it.Quantity
			break
		}
	}

	if err := u.repo.UpdateRequestItemQuantity(ctx, requestID, resourceID, newQty); err != nil {
		return err
	}

	u.audit(ctx, actor, entity.AuditDemandUpdated, "delivery_request_item", requestID,
		map[string]interface{}{"resource_id": resourceID, "quantity": oldQty},
		map[string]interface{}{"resource_id": resourceID, "quantity": newQty}, "")

	// Auto-upgrade priority on large quantity increases
	if newQty > oldQty*1.5 && req.Priority == entity.PriorityCritical {
		// already at top non-urgent, nothing to upgrade
	} else if newQty > oldQty*1.5 {
		newPriority, ok := escalatePriority(req.Priority)
		if ok {
			_ = u.repo.UpdateRequestPriority(ctx, requestID, newPriority)
		}
	}

	return nil
}

// --- Allocation management (DISPATCHER) ---

// AllocatePending runs the allocation algorithm on all pending requests, ordered by urgency score.
func (u *UseCase) AllocatePending(ctx context.Context, actor dto.UserClaims) (int, error) {
	reqs, err := u.repo.GetPendingRequests(ctx)
	if err != nil {
		return 0, err
	}

	// Sort by urgency score descending
	sort.Slice(reqs, func(i, j int) bool {
		return urgencyScore(reqs[i]) > urgencyScore(reqs[j])
	})

	allocated := 0
	for _, req := range reqs {
		if err := u.autoAllocate(ctx, actor, &req, entity.AllocationStatusPlanned); err != nil {
			u.logger.Warn("auto-allocate failed for request", "request_id", req.ID, "error", err)
			continue
		}
		allocated++
	}
	return allocated, nil
}

// ApproveAllocation moves a planned allocation to approved.
func (u *UseCase) ApproveAllocation(ctx context.Context, actor dto.UserClaims, allocationID uint) (entity.Allocation, error) {
	alloc, err := u.repo.GetAllocationByID(ctx, allocationID)
	if err != nil {
		return entity.Allocation{}, err
	}
	if alloc.Status != entity.AllocationStatusPlanned {
		return entity.Allocation{}, fmt.Errorf("%w: allocation is not in planned status", entity.ErrInvalidStatusTransition)
	}

	if err := u.repo.UpdateAllocationStatus(ctx, allocationID, entity.AllocationStatusApproved, nil); err != nil {
		return entity.Allocation{}, err
	}
	alloc.Status = entity.AllocationStatusApproved

	u.audit(ctx, actor, entity.AuditAllocationApproved, "allocation", allocationID, entity.AllocationStatusPlanned, entity.AllocationStatusApproved, "")
	return alloc, nil
}

// RejectAllocation cancels an allocation and releases the reserved inventory.
func (u *UseCase) RejectAllocation(ctx context.Context, actor dto.UserClaims, allocationID uint, reason string) error {
	alloc, err := u.repo.GetAllocationByID(ctx, allocationID)
	if err != nil {
		return err
	}
	if alloc.Status != entity.AllocationStatusPlanned && alloc.Status != entity.AllocationStatusApproved {
		return fmt.Errorf("%w: can only reject planned or approved allocations", entity.ErrInvalidStatusTransition)
	}

	// Release the reserved inventory
	if err := u.repo.AdjustInventory(ctx, alloc.SourceWarehouseID, alloc.ResourceID, alloc.Quantity); err != nil {
		return err
	}

	if err := u.repo.UpdateAllocationStatus(ctx, allocationID, entity.AllocationStatusCancelled, nil); err != nil {
		return err
	}

	// If all allocations for this request are now cancelled, revert request to pending
	allCancelled, err := u.repo.AllAllocationsForRequestHaveStatus(ctx, alloc.RequestID, entity.AllocationStatusCancelled)
	if err == nil && allCancelled {
		_ = u.repo.UpdateRequestStatus(ctx, alloc.RequestID, entity.StatusPending)
	}

	u.audit(ctx, actor, entity.AuditAllocationRejected, "allocation", allocationID,
		alloc.Status, entity.AllocationStatusCancelled, reason)
	return nil
}

// ApproveAllAllocations approves all planned allocations for a given request.
func (u *UseCase) ApproveAllAllocations(ctx context.Context, actor dto.UserClaims, requestID uint) error {
	allocs, err := u.repo.GetAllocationsByRequest(ctx, requestID)
	if err != nil {
		return err
	}
	for _, a := range allocs {
		if a.Status == entity.AllocationStatusPlanned {
			if _, err := u.ApproveAllocation(ctx, actor, a.ID); err != nil {
				return err
			}
		}
	}
	return nil
}

// DispatchAllocation marks goods as physically dispatched from the source warehouse.
// This is the hard inventory deduction point.
func (u *UseCase) DispatchAllocation(ctx context.Context, actor dto.UserClaims, allocationID uint) (entity.Allocation, error) {
	alloc, err := u.repo.GetAllocationByID(ctx, allocationID)
	if err != nil {
		return entity.Allocation{}, err
	}
	if alloc.Status != entity.AllocationStatusApproved {
		return entity.Allocation{}, fmt.Errorf("%w: allocation must be approved before dispatch", entity.ErrInvalidStatusTransition)
	}

	now := time.Now()
	if err := u.repo.UpdateAllocationStatus(ctx, allocationID, entity.AllocationStatusInTransit, &now); err != nil {
		return entity.Allocation{}, err
	}
	alloc.Status = entity.AllocationStatusInTransit
	alloc.DispatchedAt = &now

	// Check if all allocations for this request are now in transit → upgrade request status
	allInTransit, err := u.repo.AllAllocationsForRequestHaveStatus(ctx, alloc.RequestID, entity.AllocationStatusInTransit)
	if err == nil && allInTransit {
		_ = u.repo.UpdateRequestStatus(ctx, alloc.RequestID, entity.StatusInTransit)
	}

	u.audit(ctx, actor, entity.AuditGoodsDispatched, "allocation", allocationID,
		entity.AllocationStatusApproved, entity.AllocationStatusInTransit, "")
	return alloc, nil
}

// GetAllocations returns allocations matching the filter.
func (u *UseCase) GetAllocations(ctx context.Context, filter dto.AllocationFilter) ([]entity.Allocation, int, error) {
	if filter.Limit == 0 {
		filter.Limit = 20
	}
	return u.repo.GetAllocations(ctx, filter)
}

// --- Nearest Stock Finder ---

// FindNearestStock returns up to 5 warehouses with surplus stock for the given resource,
// ranked by (surplus × 0.6) - (normalized_distance × 0.4).
func (u *UseCase) FindNearestStock(ctx context.Context, resourceID, customerID uint, needed float64) ([]dto.NearestStockResult, error) {
	custLat, custLon, err := u.repo.GetCustomerCoords(ctx, customerID)
	if err != nil {
		return nil, err
	}

	warehouses, err := u.repo.GetAllWarehousesWithResource(ctx, resourceID)
	if err != nil {
		return nil, err
	}

	type candidate struct {
		dto.NearestStockResult
		rawDist float64
		surplus float64
	}

	var maxDist float64
	var candidates []candidate
	for _, w := range warehouses {
		surplus := w.Quantity * (1 - safetyStockRatio)
		if surplus <= 0 {
			continue
		}
		dist := haversineKm(w.Lat, w.Lon, custLat, custLon)
		if dist > maxDist {
			maxDist = dist
		}
		candidates = append(candidates, candidate{
			NearestStockResult: dto.NearestStockResult{
				WarehouseID:           w.WarehouseID,
				WarehouseName:         w.Name, // populated by GetAllWarehousesWithResource
				Surplus:               surplus,
				DistanceKm:            dist,
				EstimatedArrivalHours: dist / avgSpeedKmH,
			},
			rawDist: dist,
			surplus: surplus,
		})
	}

	for i := range candidates {
		normDist := 0.0
		if maxDist > 0 {
			normDist = candidates[i].rawDist / maxDist
		}
		candidates[i].Score = candidates[i].surplus*0.6 - normDist*0.4
	}

	sort.Slice(candidates, func(i, j int) bool {
		return candidates[i].Score > candidates[j].Score
	})

	top := maxNearestStock
	if len(candidates) < top {
		top = len(candidates)
	}
	result := make([]dto.NearestStockResult, top)
	for i := range result {
		result[i] = candidates[i].NearestStockResult
	}
	return result, nil
}

// --- Audit Log ---

func (u *UseCase) GetAuditLog(ctx context.Context, filter dto.AuditFilter) ([]entity.AuditEntry, int, error) {
	if filter.Limit == 0 {
		filter.Limit = 50
	}
	return u.auditRepo.GetAll(ctx, filter)
}

// --- Internal helpers ---

// autoAllocate runs the allocation algorithm for all items of a request.
// initialStatus is either AllocationStatusPlanned (normal) or AllocationStatusApproved (urgent).
func (u *UseCase) autoAllocate(ctx context.Context, actor dto.UserClaims, req *entity.DeliveryRequest, initialStatus entity.AllocationStatus) error {
	items, err := u.repo.GetRequestItems(ctx, req.ID)
	if err != nil {
		return err
	}

	var anyShortfall bool
	for _, item := range items {
		allocated, err := u.allocateItem(ctx, req.ID, req.DestinationID, item.ResourceID, item.Quantity, initialStatus)
		if err != nil {
			return err
		}
		if allocated < item.Quantity {
			anyShortfall = true
			u.logger.Warn("partial allocation",
				"request_id", req.ID,
				"resource_id", item.ResourceID,
				"needed", item.Quantity,
				"allocated", allocated,
			)
		}
	}

	// Mark request as allocated if at least something was allocated
	allocs, _ := u.repo.GetAllocationsByRequest(ctx, req.ID)
	if len(allocs) > 0 {
		if err := u.repo.UpdateRequestStatus(ctx, req.ID, entity.StatusAllocated); err != nil {
			return err
		}
		req.Status = entity.StatusAllocated
		u.audit(ctx, actor, entity.AuditAllocationCreated, "delivery_request", req.ID, entity.StatusPending, entity.StatusAllocated, "")
	}

	if anyShortfall {
		return entity.ErrInsufficientStock
	}
	return nil
}

// allocateItem distributes neededQty of resourceID from warehouses to a single request.
// Returns the total quantity actually allocated.
func (u *UseCase) allocateItem(ctx context.Context, requestID, customerID, resourceID uint, neededQty float64, status entity.AllocationStatus) (float64, error) {
	warehouses, err := u.repo.GetInventoryByResource(ctx, resourceID)
	if err != nil {
		return 0, err
	}
	if len(warehouses) == 0 {
		return 0, nil
	}

	custLat, custLon, err := u.repo.GetCustomerCoords(ctx, customerID)
	if err != nil {
		return 0, err
	}

	type candidate struct {
		warehouseID uint
		surplus     float64
		distKm      float64
	}

	var candidates []candidate
	var maxDist float64

	for _, w := range warehouses {
		surplus := w.Quantity * (1 - safetyStockRatio)
		if surplus <= 0 {
			continue
		}
		dist := haversineKm(w.Lat, w.Lon, custLat, custLon)
		candidates = append(candidates, candidate{w.WarehouseID, surplus, dist})
		if dist > maxDist {
			maxDist = dist
		}
	}

	sort.Slice(candidates, func(i, j int) bool {
		ni := candidates[i].distKm / (maxDist + 1)
		nj := candidates[j].distKm / (maxDist + 1)
		si := candidates[i].surplus*0.6 - ni*0.4
		sj := candidates[j].surplus*0.6 - nj*0.4
		return si > sj
	})

	remaining := neededQty
	for _, c := range candidates {
		if remaining <= 0 {
			break
		}
		qty := c.surplus
		if qty > remaining {
			qty = remaining
		}

		alloc := entity.Allocation{
			RequestID:         requestID,
			SourceWarehouseID: c.warehouseID,
			ResourceID:        resourceID,
			Quantity:          qty,
			Status:            status,
		}
		if _, err := u.repo.InsertAllocation(ctx, alloc); err != nil {
			return neededQty - remaining, err
		}
		// Reserve (deduct from available quantity)
		if err := u.repo.AdjustInventory(ctx, c.warehouseID, resourceID, -qty); err != nil {
			return neededQty - remaining, err
		}
		remaining -= qty
	}

	return neededQty - remaining, nil
}

// releaseAllocations returns all non-dispatched allocations back to inventory.
func (u *UseCase) releaseAllocations(ctx context.Context, requestID uint) error {
	allocs, err := u.repo.GetAllocationsByRequest(ctx, requestID)
	if err != nil {
		return err
	}
	for _, a := range allocs {
		if a.Status == entity.AllocationStatusPlanned || a.Status == entity.AllocationStatusApproved {
			if err := u.repo.AdjustInventory(ctx, a.SourceWarehouseID, a.ResourceID, a.Quantity); err != nil {
				return err
			}
			_ = u.repo.UpdateAllocationStatus(ctx, a.ID, entity.AllocationStatusCancelled, nil)
		}
	}
	return nil
}

// audit writes an audit entry best-effort (never fails the calling operation).
func (u *UseCase) audit(ctx context.Context, actor dto.UserClaims, action entity.AuditAction, entityType string, entityID uint, before, after interface{}, ip string) {
	var beforeStr, afterStr *string
	if before != nil {
		if b, err := json.Marshal(before); err == nil {
			s := string(b)
			beforeStr = &s
		}
	}
	if after != nil {
		if a, err := json.Marshal(after); err == nil {
			s := string(a)
			afterStr = &s
		}
	}

	var actorID *uint
	if actor.UserID > 0 {
		id := uint(actor.UserID)
		actorID = &id
	}
	var eid *uint
	if entityID > 0 {
		eid = &entityID
	}

	entry := entity.AuditEntry{
		ActorID:     actorID,
		ActorRole:   string(actor.Role),
		Action:      action,
		EntityType:  entityType,
		EntityID:    eid,
		BeforeValue: beforeStr,
		AfterValue:  afterStr,
		IPAddress:   nil,
	}

	if err := u.auditRepo.Insert(ctx, entry); err != nil {
		u.logger.Warn("audit log insert failed", "error", err)
	}
}

// --- Priority helpers ---

// urgencyScore computes the processing priority score for queue ordering.
func urgencyScore(req entity.DeliveryRequest) float64 {
	var score float64
	switch req.Priority {
	case entity.PriorityUrgent:
		score = 1000
	case entity.PriorityCritical:
		score = 100
	case entity.PriorityElevated:
		score = 10
	default:
		score = 1
	}

	if req.ArriveTill != nil {
		hours := time.Until(*req.ArriveTill).Hours()
		switch {
		case hours < 2:
			score += 500
		case hours < 6:
			score += 100
		case hours < 24:
			score += 20
		}
	}

	score += time.Since(req.CreatedAt).Hours() * 2 // wait-time drift
	return score
}

func escalatePriority(p entity.DeliveryPriority) (entity.DeliveryPriority, bool) {
	switch p {
	case entity.PriorityNormal:
		return entity.PriorityElevated, true
	case entity.PriorityElevated:
		return entity.PriorityCritical, true
	case entity.PriorityCritical:
		return entity.PriorityUrgent, true
	default:
		return p, false
	}
}

// --- Geo helpers ---

func haversineKm(lat1, lon1, lat2, lon2 float64) float64 {
	dLat := (lat2 - lat1) * math.Pi / 180
	dLon := (lon2 - lon1) * math.Pi / 180
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180)*math.Cos(lat2*math.Pi/180)*
			math.Sin(dLon/2)*math.Sin(dLon/2)
	return earthRadiusKm * 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
}
