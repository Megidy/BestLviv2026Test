package persistent

import (
	"context"
	"fmt"

	"github.com/Megidy/BestLviv2026Test/internal/dto"
	"github.com/Megidy/BestLviv2026Test/internal/entity"
	"github.com/jackc/pgx/v5/pgxpool"
)

type AuditRepo struct {
	pool *pgxpool.Pool
}

func NewAuditRepo(pool *pgxpool.Pool) *AuditRepo {
	return &AuditRepo{pool: pool}
}

func (r *AuditRepo) Insert(ctx context.Context, e entity.AuditEntry) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO audit_log (actor_id, actor_role, action, entity_type, entity_id, before_value, after_value, ip_address)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
		e.ActorID, e.ActorRole, e.Action, nullStr(e.EntityType), e.EntityID,
		e.BeforeValue, e.AfterValue, nullStr(e.IPAddress),
	)
	return err
}

func (r *AuditRepo) GetAll(ctx context.Context, filter dto.AuditFilter) ([]entity.AuditEntry, int, error) {
	query := `SELECT id, actor_id, actor_role, action, entity_type, entity_id, before_value, after_value, ip_address, created_at,
	                 COUNT(*) OVER() AS total
	          FROM audit_log WHERE 1=1`
	args := []interface{}{}
	n := 1

	if filter.ActorID > 0 {
		query += fmt.Sprintf(" AND actor_id = $%d", n)
		args = append(args, filter.ActorID)
		n++
	}
	if filter.Action != "" {
		query += fmt.Sprintf(" AND action = $%d", n)
		args = append(args, filter.Action)
		n++
	}
	if filter.EntityType != "" {
		query += fmt.Sprintf(" AND entity_type = $%d", n)
		args = append(args, filter.EntityType)
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
		entries []entity.AuditEntry
		total   int
	)
	for rows.Next() {
		var e entity.AuditEntry
		if err := rows.Scan(&e.ID, &e.ActorID, &e.ActorRole, &e.Action, &e.EntityType, &e.EntityID,
			&e.BeforeValue, &e.AfterValue, &e.IPAddress, &e.CreatedAt, &total); err != nil {
			return nil, 0, err
		}
		entries = append(entries, e)
	}
	return entries, total, rows.Err()
}

func nullStr(s string) interface{} {
	if s == "" {
		return nil
	}
	return s
}
