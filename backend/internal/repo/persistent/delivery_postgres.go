package persistent

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/Megidy/BestLviv2026Test/internal/dto"
	"github.com/Megidy/BestLviv2026Test/internal/entity"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type DeliveryRepo struct {
	pool *pgxpool.Pool
}

func NewDeliveryRepo(pool *pgxpool.Pool) *DeliveryRepo {
	return &DeliveryRepo{pool: pool}
}

// --- Delivery Requests ---

func (r *DeliveryRepo) InsertRequest(ctx context.Context, req entity.DeliveryRequest) (entity.DeliveryRequest, error) {
	err := r.pool.QueryRow(ctx,
		`INSERT INTO delivery_requests
		 (destination_id, resource_id, user_id, quantity, priority, status, arrive_till)
		 VALUES ($1, $2, $3, $4, $5, $6, $7)
		 RETURNING id, created_at, updated_at`,
		req.DestinationID, req.ResourceID, req.UserID, req.Quantity, req.Priority, req.Status, req.ArriveTill,
	).Scan(&req.ID, &req.CreatedAt, &req.UpdatedAt)
	if err != nil {
		return entity.DeliveryRequest{}, fmt.Errorf("insert delivery request: %w", err)
	}
	return req, nil
}

func (r *DeliveryRepo) InsertRequestItems(ctx context.Context, requestID uint, items []entity.DeliveryRequestItem) ([]entity.DeliveryRequestItem, error) {
	result := make([]entity.DeliveryRequestItem, len(items))
	for i, item := range items {
		item.RequestID = requestID
		err := r.pool.QueryRow(ctx,
			`INSERT INTO delivery_request_items (request_id, resource_id, quantity)
			 VALUES ($1, $2, $3)
			 RETURNING id, created_at, updated_at`,
			item.RequestID, item.ResourceID, item.Quantity,
		).Scan(&item.ID, &item.CreatedAt, &item.UpdatedAt)
		if err != nil {
			return nil, fmt.Errorf("insert request item: %w", err)
		}
		result[i] = item
	}
	return result, nil
}

func (r *DeliveryRepo) GetRequestByID(ctx context.Context, id uint) (entity.DeliveryRequest, error) {
	var req entity.DeliveryRequest
	err := r.pool.QueryRow(ctx,
		`SELECT id, destination_id, resource_id, user_id, quantity, priority, status, arrive_till, created_at, updated_at
		 FROM delivery_requests WHERE id = $1`,
		id,
	).Scan(&req.ID, &req.DestinationID, &req.ResourceID, &req.UserID, &req.Quantity,
		&req.Priority, &req.Status, &req.ArriveTill, &req.CreatedAt, &req.UpdatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return entity.DeliveryRequest{}, entity.ErrNotFound
	}
	if err != nil {
		return entity.DeliveryRequest{}, err
	}
	return req, nil
}

func (r *DeliveryRepo) GetRequests(ctx context.Context, filter dto.DeliveryRequestFilter) ([]entity.DeliveryRequest, int, error) {
	query := `SELECT id, destination_id, resource_id, user_id, quantity, priority, status, arrive_till, created_at, updated_at,
	                 COUNT(*) OVER() AS total
	          FROM delivery_requests WHERE 1=1`
	args := []interface{}{}
	n := 1

	if filter.Status != "" {
		query += fmt.Sprintf(" AND status = $%d", n)
		args = append(args, filter.Status)
		n++
	}
	if filter.Priority != "" {
		query += fmt.Sprintf(" AND priority = $%d", n)
		args = append(args, filter.Priority)
		n++
	}
	if filter.UserID > 0 {
		query += fmt.Sprintf(" AND user_id = $%d", n)
		args = append(args, filter.UserID)
		n++
	}

	query += fmt.Sprintf(" ORDER BY created_at DESC LIMIT $%d OFFSET $%d", n, n+1)
	args = append(args, filter.Limit, filter.Offset)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("get requests: %w", err)
	}
	defer rows.Close()

	var (
		requests []entity.DeliveryRequest
		total    int
	)
	for rows.Next() {
		var req entity.DeliveryRequest
		if err := rows.Scan(&req.ID, &req.DestinationID, &req.ResourceID, &req.UserID, &req.Quantity,
			&req.Priority, &req.Status, &req.ArriveTill, &req.CreatedAt, &req.UpdatedAt, &total); err != nil {
			return nil, 0, err
		}
		requests = append(requests, req)
	}
	return requests, total, rows.Err()
}

func (r *DeliveryRepo) GetRequestItems(ctx context.Context, requestID uint) ([]entity.DeliveryRequestItem, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, request_id, resource_id, quantity, created_at, updated_at
		 FROM delivery_request_items WHERE request_id = $1`,
		requestID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []entity.DeliveryRequestItem
	for rows.Next() {
		var item entity.DeliveryRequestItem
		if err := rows.Scan(&item.ID, &item.RequestID, &item.ResourceID, &item.Quantity, &item.CreatedAt, &item.UpdatedAt); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *DeliveryRepo) UpdateRequestStatus(ctx context.Context, id uint, status entity.DeliveryStatus) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE delivery_requests SET status = $1 WHERE id = $2`,
		status, id,
	)
	return err
}

func (r *DeliveryRepo) UpdateRequestPriority(ctx context.Context, id uint, priority entity.DeliveryPriority) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE delivery_requests SET priority = $1 WHERE id = $2`,
		priority, id,
	)
	return err
}

func (r *DeliveryRepo) UpdateRequestItemQuantity(ctx context.Context, requestID, resourceID uint, quantity float64) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE delivery_request_items SET quantity = $1 WHERE request_id = $2 AND resource_id = $3`,
		quantity, requestID, resourceID,
	)
	return err
}

// --- Allocations ---

func (r *DeliveryRepo) InsertAllocation(ctx context.Context, a entity.Allocation) (entity.Allocation, error) {
	err := r.pool.QueryRow(ctx,
		`INSERT INTO allocations (request_id, source_warehouse_id, resource_id, quantity, allocation_status)
		 VALUES ($1, $2, $3, $4, $5)
		 RETURNING id, created_at, updated_at`,
		a.RequestID, a.SourceWarehouseID, a.ResourceID, a.Quantity, a.Status,
	).Scan(&a.ID, &a.CreatedAt, &a.UpdatedAt)
	if err != nil {
		return entity.Allocation{}, fmt.Errorf("insert allocation: %w", err)
	}
	return a, nil
}

func (r *DeliveryRepo) GetAllocationByID(ctx context.Context, id uint) (entity.Allocation, error) {
	var a entity.Allocation
	err := r.pool.QueryRow(ctx,
		`SELECT id, request_id, source_warehouse_id, COALESCE(resource_id, 0), quantity, allocation_status, dispatched_at, created_at, updated_at
		 FROM allocations WHERE id = $1`,
		id,
	).Scan(&a.ID, &a.RequestID, &a.SourceWarehouseID, &a.ResourceID, &a.Quantity, &a.Status, &a.DispatchedAt, &a.CreatedAt, &a.UpdatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return entity.Allocation{}, entity.ErrNotFound
	}
	return a, err
}

func (r *DeliveryRepo) GetAllocationsByRequest(ctx context.Context, requestID uint) ([]entity.Allocation, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, request_id, source_warehouse_id, COALESCE(resource_id, 0), quantity, allocation_status, dispatched_at, created_at, updated_at
		 FROM allocations WHERE request_id = $1`,
		requestID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var allocs []entity.Allocation
	for rows.Next() {
		var a entity.Allocation
		if err := rows.Scan(&a.ID, &a.RequestID, &a.SourceWarehouseID, &a.ResourceID, &a.Quantity, &a.Status, &a.DispatchedAt, &a.CreatedAt, &a.UpdatedAt); err != nil {
			return nil, err
		}
		allocs = append(allocs, a)
	}
	return allocs, rows.Err()
}

func (r *DeliveryRepo) GetAllocations(ctx context.Context, filter dto.AllocationFilter) ([]entity.Allocation, int, error) {
	query := `SELECT id, request_id, source_warehouse_id, COALESCE(resource_id, 0), quantity, allocation_status, dispatched_at, created_at, updated_at,
	                 COUNT(*) OVER() AS total
	          FROM allocations WHERE 1=1`
	args := []interface{}{}
	n := 1

	if filter.Status != "" {
		query += fmt.Sprintf(" AND allocation_status = $%d", n)
		args = append(args, filter.Status)
		n++
	}
	if filter.RequestID > 0 {
		query += fmt.Sprintf(" AND request_id = $%d", n)
		args = append(args, filter.RequestID)
		n++
	}

	query += fmt.Sprintf(" ORDER BY created_at DESC LIMIT $%d OFFSET $%d", n, n+1)
	args = append(args, filter.Limit, filter.Offset)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var (
		allocs []entity.Allocation
		total  int
	)
	for rows.Next() {
		var a entity.Allocation
		if err := rows.Scan(&a.ID, &a.RequestID, &a.SourceWarehouseID, &a.ResourceID, &a.Quantity, &a.Status, &a.DispatchedAt, &a.CreatedAt, &a.UpdatedAt, &total); err != nil {
			return nil, 0, err
		}
		allocs = append(allocs, a)
	}
	return allocs, total, rows.Err()
}

func (r *DeliveryRepo) UpdateAllocationStatus(ctx context.Context, id uint, status entity.AllocationStatus, dispatchedAt *time.Time) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE allocations SET allocation_status = $1, dispatched_at = $2 WHERE id = $3`,
		status, dispatchedAt, id,
	)
	return err
}

// --- Inventory helpers ---

func (r *DeliveryRepo) GetInventoryByResource(ctx context.Context, resourceID uint) ([]entity.WarehouseInventory, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT i.warehouse_id, i.quantity, w.latitude, w.longitude
		 FROM inventories i
		 JOIN warehouses w ON i.warehouse_id = w.id
		 WHERE i.resource_id = $1 AND i.quantity > 0`,
		resourceID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []entity.WarehouseInventory
	for rows.Next() {
		var w entity.WarehouseInventory
		if err := rows.Scan(&w.WarehouseID, &w.Quantity, &w.Lat, &w.Lon); err != nil {
			return nil, err
		}
		result = append(result, w)
	}
	return result, rows.Err()
}

func (r *DeliveryRepo) GetWarehouseInventory(ctx context.Context, warehouseID, resourceID uint) (float64, error) {
	var qty float64
	err := r.pool.QueryRow(ctx,
		`SELECT quantity FROM inventories WHERE warehouse_id = $1 AND resource_id = $2`,
		warehouseID, resourceID,
	).Scan(&qty)
	if errors.Is(err, pgx.ErrNoRows) {
		return 0, nil
	}
	return qty, err
}

// AdjustInventory adds delta to a warehouse's inventory (use negative delta to deduct).
func (r *DeliveryRepo) AdjustInventory(ctx context.Context, warehouseID, resourceID uint, delta float64) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE inventories SET quantity = quantity + $1
		 WHERE warehouse_id = $2 AND resource_id = $3`,
		delta, warehouseID, resourceID,
	)
	return err
}

func (r *DeliveryRepo) GetCustomerCoords(ctx context.Context, customerID uint) (lat, lon float64, err error) {
	err = r.pool.QueryRow(ctx,
		`SELECT latitude, longitude FROM customers WHERE id = $1`,
		customerID,
	).Scan(&lat, &lon)
	if errors.Is(err, pgx.ErrNoRows) {
		return 0, 0, entity.ErrNotFound
	}
	return lat, lon, err
}

// --- Nearest Stock ---

func (r *DeliveryRepo) GetAllWarehousesWithResource(ctx context.Context, resourceID uint) ([]entity.WarehouseInventory, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT i.warehouse_id, w.name, i.quantity, w.latitude, w.longitude
		 FROM inventories i
		 JOIN warehouses w ON i.warehouse_id = w.id
		 WHERE i.resource_id = $1 AND i.quantity > 0
		 ORDER BY i.quantity DESC`,
		resourceID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []entity.WarehouseInventory
	for rows.Next() {
		var w entity.WarehouseInventory
		if err := rows.Scan(&w.WarehouseID, &w.Name, &w.Quantity, &w.Lat, &w.Lon); err != nil {
			return nil, err
		}
		result = append(result, w)
	}
	return result, rows.Err()
}

// --- Pending requests for batch allocation ---

func (r *DeliveryRepo) GetPendingRequests(ctx context.Context) ([]entity.DeliveryRequest, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, destination_id, resource_id, user_id, quantity, priority, status, arrive_till, created_at, updated_at
		 FROM delivery_requests WHERE status = 'pending'
		 ORDER BY created_at ASC`,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var reqs []entity.DeliveryRequest
	for rows.Next() {
		var req entity.DeliveryRequest
		if err := rows.Scan(&req.ID, &req.DestinationID, &req.ResourceID, &req.UserID, &req.Quantity,
			&req.Priority, &req.Status, &req.ArriveTill, &req.CreatedAt, &req.UpdatedAt); err != nil {
			return nil, err
		}
		reqs = append(reqs, req)
	}
	return reqs, rows.Err()
}

// AllAllocationsForRequestHaveStatus returns true if every allocation for the given request is in the given status.
func (r *DeliveryRepo) AllAllocationsForRequestHaveStatus(ctx context.Context, requestID uint, status entity.AllocationStatus) (bool, error) {
	var count, matching int
	err := r.pool.QueryRow(ctx,
		`SELECT COUNT(*), COUNT(*) FILTER (WHERE allocation_status = $1)
		 FROM allocations WHERE request_id = $2`,
		status, requestID,
	).Scan(&count, &matching)
	if err != nil {
		return false, err
	}
	return count > 0 && count == matching, nil
}

// HasAnyAllocationWithStatus checks if at least one allocation for the request has the given status.
func (r *DeliveryRepo) HasAnyAllocationWithStatus(ctx context.Context, requestID uint, statuses ...entity.AllocationStatus) (bool, error) {
	if len(statuses) == 0 {
		return false, nil
	}
	placeholders := make([]string, len(statuses))
	args := []interface{}{requestID}
	for i, s := range statuses {
		placeholders[i] = fmt.Sprintf("$%d", i+2)
		args = append(args, s)
	}
	query := fmt.Sprintf(
		`SELECT EXISTS(SELECT 1 FROM allocations WHERE request_id = $1 AND allocation_status IN (%s))`,
		strings.Join(placeholders, ","),
	)
	var exists bool
	return exists, r.pool.QueryRow(ctx, query, args...).Scan(&exists)
}
