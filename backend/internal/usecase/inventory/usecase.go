package inventory

import (
	"context"

	"github.com/Megidy/BestLviv2026Test/internal/dto"
)

type inventoryRepo interface {
	GetAllWithPagination(ctx context.Context, filter dto.GetAllInventoryFilter) (dto.GetAllInventoryResponse, error)
}
type UseCase struct {
	inventoryRepo inventoryRepo
}

func New(inventoryRepo inventoryRepo) *UseCase {
	return &UseCase{
		inventoryRepo: inventoryRepo,
	}
}

func (u *UseCase) GetAllWithPagination(ctx context.Context, filter dto.GetAllInventoryFilter) (dto.GetAllInventoryResponse, error) {
	return u.inventoryRepo.GetAllWithPagination(ctx, filter)
}
