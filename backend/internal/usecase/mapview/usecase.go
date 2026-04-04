package mapview

import (
	"context"

	"github.com/Megidy/BestLviv2026Test/internal/entity"
)

type mapRepo interface {
	GetMapPoints(ctx context.Context) ([]entity.MapPoint, error)
}

type UseCase struct {
	repo mapRepo
}

func New(repo mapRepo) *UseCase {
	return &UseCase{repo: repo}
}

func (u *UseCase) GetMapPoints(ctx context.Context) ([]entity.MapPoint, error) {
	return u.repo.GetMapPoints(ctx)
}
