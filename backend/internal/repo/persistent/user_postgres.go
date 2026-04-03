package persistent

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/Megidy/BestLviv2026Test/internal/entity"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type UserRepo struct {
	pool *pgxpool.Pool
}

func NewUserRepo(pool *pgxpool.Pool) *UserRepo {
	return &UserRepo{
		pool: pool,
	}
}

func (r *UserRepo) GetByUsername(ctx context.Context, username string) (entity.User, error) {
	query := `
		SELECT id, username, password_hash, role, warehouse_id, created_at, updated_at 
		FROM users 
		WHERE username = $1
	`
	var user entity.User
	var locationID sql.NullInt64

	err := r.pool.QueryRow(ctx, query, username).Scan(
		&user.Id,
		&user.Username,
		&user.PasswordHash,
		&user.Role,
		&locationID,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return entity.User{}, fmt.Errorf("user with username %s not found: %w", username, entity.ErrUserNotFound)
		}
		return entity.User{}, fmt.Errorf("failed to get user by username: %w", err)
	}

	if locationID.Valid {
		user.WarehouseId = int(locationID.Int64)
	}

	return user, nil
}

func (r *UserRepo) GetById(ctx context.Context, id int) (entity.User, error) {
	query := `
		SELECT id, username, password_hash, role, warehouse_id, created_at, updated_at 
		FROM users 
		WHERE id = $1
	`
	var user entity.User
	var locationID sql.NullInt64

	err := r.pool.QueryRow(ctx, query, id).Scan(
		&user.Id,
		&user.Username,
		&user.PasswordHash,
		&user.Role,
		&locationID,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return entity.User{}, fmt.Errorf("user with id %d not found: %w", id, entity.ErrUserNotFound)
		}
		return entity.User{}, fmt.Errorf("failed to get user by id: %w", err)
	}

	if locationID.Valid {
		user.WarehouseId = int(locationID.Int64)
	}

	return user, nil
}

func (r *UserRepo) Create(ctx context.Context, user entity.User) (int, error) {
	query := `
INSERT INTO users(username, password_hash, role, warehouse_id) 
VALUES($1, $2, $3, $4)
RETURNING id
`

	var warehouseId *int

	if user.WarehouseId != 0 {
		warehouseId = &user.WarehouseId
	}

	var id int
	err := r.pool.QueryRow(ctx, query, user.Username, user.PasswordHash, user.Role, warehouseId).Scan(
		&id,
	)
	if err != nil {
		return 0, fmt.Errorf("failed to scan row: %w", err)
	}

	return id, nil
}
