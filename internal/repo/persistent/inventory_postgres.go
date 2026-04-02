package persistent

import (
	"context"
	"fmt"

	"github.com/Megidy/BestLviv2026Test/internal/dto"
	"github.com/jackc/pgx/v5/pgxpool"
)

type InventoryRepo struct {
	pool *pgxpool.Pool
}

func NewInventoryRepo(pool *pgxpool.Pool) *InventoryRepo {
	return &InventoryRepo{
		pool: pool,
	}
}
func (r *InventoryRepo) GetAllWithPagination(ctx context.Context, filter dto.GetAllInventoryFilter) (dto.GetAllInventoryResponse, error) {
	query := `
SELECT 
	i.id, i.location_id, i.resource_id, i.quantity, i.created_at, i.updated_at,
	r.id, r.name, r.category, r.unit_measure, r.logo_uri, r.created_at, r.updated_at,
	COUNT(*) OVER() as total_count
FROM inventories i
JOIN resources r ON i.resource_id = r.id
WHERE 1=1
	`

	args := make([]interface{}, 0)
	argId := 1

	if filter.LocationId > 0 {
		args = append(args, filter.LocationId)
		argId++
	}

	if filter.ResourceName != "" {
		query += fmt.Sprintf(" AND r.name ILIKE $%d", argId)
		args = append(args, "%"+filter.ResourceName+"%")
		argId++
	}

	if filter.ResourceCategory != "" {
		query += fmt.Sprintf(" AND r.category = $%d", argId)
		args = append(args, filter.ResourceCategory)
		argId++
	}

	limit := filter.Limit

	offset := filter.Offset

	query += fmt.Sprintf(" ORDER BY i.id DESC LIMIT $%d OFFSET $%d", argId, argId+1)
	args = append(args, limit, offset)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return dto.GetAllInventoryResponse{}, fmt.Errorf("failed to execute query: %w", err)
	}
	defer rows.Close()

	response := dto.GetAllInventoryResponse{
		InventoryUnits: make([]dto.InventoryUnit, 0),
		Total:          0,
	}

	for rows.Next() {
		var unit dto.InventoryUnit
		var total int

		err := rows.Scan(
			&unit.Inventory.Id,
			&unit.Inventory.LocationId,
			&unit.Inventory.ResourceId,
			&unit.Inventory.Quantity,
			&unit.Inventory.CreatedAt,
			&unit.Inventory.UpdatedAt,
			&unit.Resource.Id,
			&unit.Resource.Name,
			&unit.Resource.Category,
			&unit.Resource.UnitMeasure,
			&unit.Resource.LogoUri,
			&unit.Resource.CreatedAt,
			&unit.Resource.UpdatedAt,
			&total,
		)
		if err != nil {
			return dto.GetAllInventoryResponse{}, fmt.Errorf("failed to scan row: %w", err)
		}

		response.InventoryUnits = append(response.InventoryUnits, unit)
		response.Total = total
	}

	if err = rows.Err(); err != nil {
		return dto.GetAllInventoryResponse{}, fmt.Errorf("rows error: %w", err)
	}

	return response, nil
}
