package repo

import (
	"context"

	"github.com/Megidy/BestLviv2026Test/internal/entity"
)

type UserRepo interface {
	GetByUsername(ctx context.Context, username string) (entity.User, error)
}
