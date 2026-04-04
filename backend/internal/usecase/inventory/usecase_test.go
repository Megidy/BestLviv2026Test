package inventory

import (
	"context"
	"reflect"
	"testing"

	"github.com/Megidy/BestLviv2026Test/internal/dto"
	"github.com/Megidy/BestLviv2026Test/internal/entity"
)

type stubInventoryRepo struct {
	gotFilter dto.GetAllInventoryFilter
	response  dto.GetAllInventoryResponse
	err       error
}

func (s *stubInventoryRepo) GetAllWithPagination(ctx context.Context, filter dto.GetAllInventoryFilter) (dto.GetAllInventoryResponse, error) {
	s.gotFilter = filter
	return s.response, s.err
}

func TestGetAllWithPaginationDelegatesToRepo(t *testing.T) {
	t.Parallel()

	filter := dto.GetAllInventoryFilter{
		LocationId:       3,
		ResourceName:     "water",
		ResourceCategory: "food",
		Limit:            10,
		Offset:           5,
	}
	expected := dto.GetAllInventoryResponse{
		InventoryUnits: []dto.InventoryUnit{
			{
				Inventory: entity.Inventory{Id: 1, LocationId: 3, ResourceId: 8, Quantity: 12},
				Resource:  entity.Resource{Id: 8, Name: "Water", Category: "food"},
			},
		},
		Total: 1,
	}
	repo := &stubInventoryRepo{response: expected}

	got, err := New(repo).GetAllWithPagination(context.Background(), filter)
	if err != nil {
		t.Fatalf("GetAllWithPagination() error = %v", err)
	}
	if !reflect.DeepEqual(repo.gotFilter, filter) {
		t.Fatalf("repo filter = %#v, want %#v", repo.gotFilter, filter)
	}
	if !reflect.DeepEqual(got, expected) {
		t.Fatalf("response = %#v, want %#v", got, expected)
	}
}
