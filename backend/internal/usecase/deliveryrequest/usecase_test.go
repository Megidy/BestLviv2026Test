package deliveryrequest

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"sort"
	"testing"
	"time"

	"github.com/Megidy/BestLviv2026Test/internal/dto"
	"github.com/Megidy/BestLviv2026Test/internal/dto/httprequest"
	"github.com/Megidy/BestLviv2026Test/internal/entity"
)

type inventoryAdjustment struct {
	warehouseID uint
	resourceID  uint
	delta       float64
}

type stubDeliveryRepo struct {
	nextRequestID    uint
	nextItemID       uint
	nextAllocationID uint
	requests         map[uint]entity.DeliveryRequest
	requestItems     map[uint][]entity.DeliveryRequestItem
	allocations      map[uint]entity.Allocation
	inventoryByRes   map[uint][]entity.WarehouseInventory
	customerCoords   map[uint][2]float64
	adjustments      []inventoryAdjustment
}

func newStubDeliveryRepo() *stubDeliveryRepo {
	return &stubDeliveryRepo{
		nextRequestID:    1,
		nextItemID:       1,
		nextAllocationID: 1,
		requests:         make(map[uint]entity.DeliveryRequest),
		requestItems:     make(map[uint][]entity.DeliveryRequestItem),
		allocations:      make(map[uint]entity.Allocation),
		inventoryByRes:   make(map[uint][]entity.WarehouseInventory),
		customerCoords:   make(map[uint][2]float64),
	}
}

func (s *stubDeliveryRepo) InsertRequest(ctx context.Context, req entity.DeliveryRequest) (entity.DeliveryRequest, error) {
	req.ID = s.nextRequestID
	s.nextRequestID++
	if req.CreatedAt.IsZero() {
		req.CreatedAt = time.Now()
	}
	s.requests[req.ID] = req
	return req, nil
}

func (s *stubDeliveryRepo) InsertRequestItems(ctx context.Context, requestID uint, items []entity.DeliveryRequestItem) ([]entity.DeliveryRequestItem, error) {
	out := make([]entity.DeliveryRequestItem, len(items))
	for i, item := range items {
		item.ID = s.nextItemID
		s.nextItemID++
		item.RequestID = requestID
		out[i] = item
	}
	s.requestItems[requestID] = out
	return out, nil
}

func (s *stubDeliveryRepo) GetRequestByID(ctx context.Context, id uint) (entity.DeliveryRequest, error) {
	req, ok := s.requests[id]
	if !ok {
		return entity.DeliveryRequest{}, entity.ErrNotFound
	}
	return req, nil
}

func (s *stubDeliveryRepo) GetRequests(ctx context.Context, filter dto.DeliveryRequestFilter) ([]entity.DeliveryRequest, int, error) {
	var requests []entity.DeliveryRequest
	for _, req := range s.requests {
		requests = append(requests, req)
	}
	return requests, len(requests), nil
}

func (s *stubDeliveryRepo) GetRequestItems(ctx context.Context, requestID uint) ([]entity.DeliveryRequestItem, error) {
	return append([]entity.DeliveryRequestItem(nil), s.requestItems[requestID]...), nil
}

func (s *stubDeliveryRepo) GetPendingRequests(ctx context.Context) ([]entity.DeliveryRequest, error) {
	var requests []entity.DeliveryRequest
	for _, req := range s.requests {
		if req.Status == entity.StatusPending {
			requests = append(requests, req)
		}
	}
	return requests, nil
}

func (s *stubDeliveryRepo) UpdateRequestStatus(ctx context.Context, id uint, status entity.DeliveryStatus) error {
	req := s.requests[id]
	req.Status = status
	s.requests[id] = req
	return nil
}

func (s *stubDeliveryRepo) UpdateRequestPriority(ctx context.Context, id uint, priority entity.DeliveryPriority) error {
	req := s.requests[id]
	req.Priority = priority
	s.requests[id] = req
	return nil
}

func (s *stubDeliveryRepo) UpdateRequestItemQuantity(ctx context.Context, requestID, resourceID uint, quantity float64) error {
	items := s.requestItems[requestID]
	for i := range items {
		if items[i].ResourceID == resourceID {
			items[i].Quantity = quantity
		}
	}
	s.requestItems[requestID] = items

	req := s.requests[requestID]
	if req.ResourceID == resourceID {
		req.Quantity = quantity
		s.requests[requestID] = req
	}
	return nil
}

func (s *stubDeliveryRepo) InsertAllocation(ctx context.Context, a entity.Allocation) (entity.Allocation, error) {
	a.ID = s.nextAllocationID
	s.nextAllocationID++
	s.allocations[a.ID] = a
	return a, nil
}

func (s *stubDeliveryRepo) GetAllocationByID(ctx context.Context, id uint) (entity.Allocation, error) {
	alloc, ok := s.allocations[id]
	if !ok {
		return entity.Allocation{}, entity.ErrNotFound
	}
	return alloc, nil
}

func (s *stubDeliveryRepo) GetAllocationsByRequest(ctx context.Context, requestID uint) ([]entity.Allocation, error) {
	var allocations []entity.Allocation
	for _, alloc := range s.allocations {
		if alloc.RequestID == requestID {
			allocations = append(allocations, alloc)
		}
	}
	sort.Slice(allocations, func(i, j int) bool {
		return allocations[i].ID < allocations[j].ID
	})
	return allocations, nil
}

func (s *stubDeliveryRepo) GetAllocations(ctx context.Context, filter dto.AllocationFilter) ([]entity.Allocation, int, error) {
	var allocations []entity.Allocation
	for _, alloc := range s.allocations {
		allocations = append(allocations, alloc)
	}
	return allocations, len(allocations), nil
}

func (s *stubDeliveryRepo) UpdateAllocationStatus(ctx context.Context, id uint, status entity.AllocationStatus, dispatchedAt *time.Time) error {
	alloc := s.allocations[id]
	alloc.Status = status
	alloc.DispatchedAt = dispatchedAt
	s.allocations[id] = alloc
	return nil
}

func (s *stubDeliveryRepo) AllAllocationsForRequestHaveStatus(ctx context.Context, requestID uint, status entity.AllocationStatus) (bool, error) {
	found := false
	for _, alloc := range s.allocations {
		if alloc.RequestID != requestID {
			continue
		}
		found = true
		if alloc.Status != status {
			return false, nil
		}
	}
	return found, nil
}

func (s *stubDeliveryRepo) HasAnyAllocationWithStatus(ctx context.Context, requestID uint, statuses ...entity.AllocationStatus) (bool, error) {
	for _, alloc := range s.allocations {
		if alloc.RequestID != requestID {
			continue
		}
		for _, status := range statuses {
			if alloc.Status == status {
				return true, nil
			}
		}
	}
	return false, nil
}

func (s *stubDeliveryRepo) GetInventoryByResource(ctx context.Context, resourceID uint) ([]entity.WarehouseInventory, error) {
	return append([]entity.WarehouseInventory(nil), s.inventoryByRes[resourceID]...), nil
}

func (s *stubDeliveryRepo) GetWarehouseInventory(ctx context.Context, warehouseID, resourceID uint) (float64, error) {
	for _, item := range s.inventoryByRes[resourceID] {
		if item.WarehouseID == warehouseID {
			return item.Quantity, nil
		}
	}
	return 0, entity.ErrNotFound
}

func (s *stubDeliveryRepo) AdjustInventory(ctx context.Context, warehouseID, resourceID uint, delta float64) error {
	items := s.inventoryByRes[resourceID]
	for i := range items {
		if items[i].WarehouseID == warehouseID {
			items[i].Quantity += delta
			s.inventoryByRes[resourceID] = items
			s.adjustments = append(s.adjustments, inventoryAdjustment{
				warehouseID: warehouseID,
				resourceID:  resourceID,
				delta:       delta,
			})
			return nil
		}
	}
	return entity.ErrNotFound
}

func (s *stubDeliveryRepo) GetCustomerCoords(ctx context.Context, customerID uint) (lat, lon float64, err error) {
	coords := s.customerCoords[customerID]
	return coords[0], coords[1], nil
}

func (s *stubDeliveryRepo) GetAllWarehousesWithResource(ctx context.Context, resourceID uint) ([]entity.WarehouseInventory, error) {
	return append([]entity.WarehouseInventory(nil), s.inventoryByRes[resourceID]...), nil
}

type stubAuditRepo struct {
	entries []entity.AuditEntry
}

func (s *stubAuditRepo) Insert(ctx context.Context, entry entity.AuditEntry) error {
	s.entries = append(s.entries, entry)
	return nil
}

func (s *stubAuditRepo) GetAll(ctx context.Context, filter dto.AuditFilter) ([]entity.AuditEntry, int, error) {
	return append([]entity.AuditEntry(nil), s.entries...), len(s.entries), nil
}

func testDeliveryLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(io.Discard, nil))
}

func TestCreateRequestUrgentRequiresArriveTill(t *testing.T) {
	t.Parallel()

	repo := newStubDeliveryRepo()
	audit := &stubAuditRepo{}
	uc := New(repo, audit, testDeliveryLogger())

	_, err := uc.CreateRequest(context.Background(), dto.UserClaims{UserID: 7, Role: entity.UserRoleWorker}, httprequest.CreateDeliveryRequest{
		DestinationID: 10,
		Priority:      entity.PriorityUrgent,
		Items: []httprequest.DeliveryItemRequest{
			{ResourceID: 5, Quantity: 10},
		},
	})
	if !errors.Is(err, entity.ErrBadRequest) {
		t.Fatalf("CreateRequest() error = %v, want %v", err, entity.ErrBadRequest)
	}
}

func TestCreateRequestUrgentAutoAllocatesInventory(t *testing.T) {
	t.Parallel()

	repo := newStubDeliveryRepo()
	repo.inventoryByRes[5] = []entity.WarehouseInventory{
		{WarehouseID: 1, Name: "A", Quantity: 100, Lat: 50.45, Lon: 30.52},
	}
	repo.customerCoords[10] = [2]float64{50.45, 30.52}

	audit := &stubAuditRepo{}
	uc := New(repo, audit, testDeliveryLogger())

	arriveTill := time.Now().Add(2 * time.Hour)
	request, err := uc.CreateRequest(context.Background(), dto.UserClaims{UserID: 7, Role: entity.UserRoleDispatcher}, httprequest.CreateDeliveryRequest{
		DestinationID: 10,
		Priority:      entity.PriorityUrgent,
		ArriveTill:    &arriveTill,
		Items: []httprequest.DeliveryItemRequest{
			{ResourceID: 5, Quantity: 20},
		},
	})
	if err != nil {
		t.Fatalf("CreateRequest() error = %v", err)
	}

	if request.Status != entity.StatusAllocated {
		t.Fatalf("request status = %q, want %q", request.Status, entity.StatusAllocated)
	}
	if len(request.Items) != 1 {
		t.Fatalf("request item count = %d, want 1", len(request.Items))
	}

	allocations, err := repo.GetAllocationsByRequest(context.Background(), request.ID)
	if err != nil {
		t.Fatalf("GetAllocationsByRequest() error = %v", err)
	}
	if len(allocations) != 1 {
		t.Fatalf("allocation count = %d, want 1", len(allocations))
	}
	if allocations[0].Status != entity.AllocationStatusApproved {
		t.Fatalf("allocation status = %q, want %q", allocations[0].Status, entity.AllocationStatusApproved)
	}
	if repo.inventoryByRes[5][0].Quantity != 80 {
		t.Fatalf("warehouse quantity = %f, want 80", repo.inventoryByRes[5][0].Quantity)
	}
	if len(audit.entries) != 3 {
		t.Fatalf("audit entry count = %d, want 3", len(audit.entries))
	}
}

func TestCancelRequestAllocatedDispatcherReleasesInventory(t *testing.T) {
	t.Parallel()

	repo := newStubDeliveryRepo()
	repo.requests[1] = entity.DeliveryRequest{
		ID:            1,
		DestinationID: 10,
		ResourceID:    5,
		UserID:        7,
		Priority:      entity.PriorityNormal,
		Status:        entity.StatusAllocated,
	}
	repo.allocations[1] = entity.Allocation{
		ID:                1,
		RequestID:         1,
		SourceWarehouseID: 2,
		ResourceID:        5,
		Quantity:          20,
		Status:            entity.AllocationStatusApproved,
	}
	repo.inventoryByRes[5] = []entity.WarehouseInventory{
		{WarehouseID: 2, Name: "B", Quantity: 60, Lat: 50.45, Lon: 30.52},
	}

	audit := &stubAuditRepo{}
	uc := New(repo, audit, testDeliveryLogger())

	err := uc.CancelRequest(context.Background(), dto.UserClaims{UserID: 99, Role: entity.UserRoleDispatcher}, 1)
	if err != nil {
		t.Fatalf("CancelRequest() error = %v", err)
	}

	if repo.requests[1].Status != entity.StatusCancelled {
		t.Fatalf("request status = %q, want %q", repo.requests[1].Status, entity.StatusCancelled)
	}
	if repo.allocations[1].Status != entity.AllocationStatusCancelled {
		t.Fatalf("allocation status = %q, want %q", repo.allocations[1].Status, entity.AllocationStatusCancelled)
	}
	if repo.inventoryByRes[5][0].Quantity != 80 {
		t.Fatalf("warehouse quantity = %f, want 80", repo.inventoryByRes[5][0].Quantity)
	}
	if len(repo.adjustments) != 1 || repo.adjustments[0].delta != 20 {
		t.Fatalf("inventory adjustments = %#v, want one +20 adjustment", repo.adjustments)
	}
}

func TestUpdateItemQuantityEscalatesPriorityOnLargeIncrease(t *testing.T) {
	t.Parallel()

	repo := newStubDeliveryRepo()
	repo.requests[1] = entity.DeliveryRequest{
		ID:         1,
		ResourceID: 5,
		UserID:     7,
		Priority:   entity.PriorityNormal,
		Status:     entity.StatusPending,
	}
	repo.requestItems[1] = []entity.DeliveryRequestItem{
		{ID: 1, RequestID: 1, ResourceID: 5, Quantity: 10},
	}

	audit := &stubAuditRepo{}
	uc := New(repo, audit, testDeliveryLogger())

	err := uc.UpdateItemQuantity(context.Background(), dto.UserClaims{UserID: 7, Role: entity.UserRoleWorker}, 1, 5, 16)
	if err != nil {
		t.Fatalf("UpdateItemQuantity() error = %v", err)
	}

	if repo.requestItems[1][0].Quantity != 16 {
		t.Fatalf("item quantity = %f, want 16", repo.requestItems[1][0].Quantity)
	}
	if repo.requests[1].Priority != entity.PriorityElevated {
		t.Fatalf("request priority = %q, want %q", repo.requests[1].Priority, entity.PriorityElevated)
	}
	if len(audit.entries) != 1 {
		t.Fatalf("audit entry count = %d, want 1", len(audit.entries))
	}
}

func TestDispatchAllocationMovesRequestToInTransitWhenAllDispatched(t *testing.T) {
	t.Parallel()

	repo := newStubDeliveryRepo()
	repo.requests[1] = entity.DeliveryRequest{
		ID:     1,
		Status: entity.StatusAllocated,
	}
	repo.allocations[1] = entity.Allocation{
		ID:                1,
		RequestID:         1,
		SourceWarehouseID: 2,
		ResourceID:        5,
		Quantity:          10,
		Status:            entity.AllocationStatusApproved,
	}
	repo.allocations[2] = entity.Allocation{
		ID:                2,
		RequestID:         1,
		SourceWarehouseID: 3,
		ResourceID:        5,
		Quantity:          10,
		Status:            entity.AllocationStatusInTransit,
		DispatchedAt:      ptrTime(time.Now()),
	}

	audit := &stubAuditRepo{}
	uc := New(repo, audit, testDeliveryLogger())

	alloc, err := uc.DispatchAllocation(context.Background(), dto.UserClaims{UserID: 99, Role: entity.UserRoleDispatcher}, 1)
	if err != nil {
		t.Fatalf("DispatchAllocation() error = %v", err)
	}

	if alloc.Status != entity.AllocationStatusInTransit {
		t.Fatalf("allocation status = %q, want %q", alloc.Status, entity.AllocationStatusInTransit)
	}
	if alloc.DispatchedAt == nil {
		t.Fatal("allocation dispatched time is nil")
	}
	if repo.requests[1].Status != entity.StatusInTransit {
		t.Fatalf("request status = %q, want %q", repo.requests[1].Status, entity.StatusInTransit)
	}
	if len(audit.entries) != 1 {
		t.Fatalf("audit entry count = %d, want 1", len(audit.entries))
	}
}

func TestFindNearestStockRanksAndLimitsResults(t *testing.T) {
	t.Parallel()

	repo := newStubDeliveryRepo()
	repo.customerCoords[10] = [2]float64{50.45, 30.52}
	repo.inventoryByRes[5] = []entity.WarehouseInventory{
		{WarehouseID: 1, Name: "One", Quantity: 10, Lat: 50.45, Lon: 30.52},
		{WarehouseID: 2, Name: "Two", Quantity: 20, Lat: 50.45, Lon: 30.52},
		{WarehouseID: 3, Name: "Three", Quantity: 30, Lat: 50.45, Lon: 30.52},
		{WarehouseID: 4, Name: "Four", Quantity: 40, Lat: 50.45, Lon: 30.52},
		{WarehouseID: 5, Name: "Five", Quantity: 50, Lat: 50.45, Lon: 30.52},
		{WarehouseID: 6, Name: "Six", Quantity: 60, Lat: 50.45, Lon: 30.52},
	}

	uc := New(repo, &stubAuditRepo{}, testDeliveryLogger())
	result, err := uc.FindNearestStock(context.Background(), 5, 10, 15)
	if err != nil {
		t.Fatalf("FindNearestStock() error = %v", err)
	}

	if len(result) != 5 {
		t.Fatalf("result count = %d, want 5", len(result))
	}
	if result[0].WarehouseID != 6 {
		t.Fatalf("top warehouse = %d, want 6", result[0].WarehouseID)
	}
	if result[4].WarehouseID != 2 {
		t.Fatalf("fifth warehouse = %d, want 2", result[4].WarehouseID)
	}
}

func ptrTime(t time.Time) *time.Time {
	return &t
}
