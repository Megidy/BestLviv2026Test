package dto

import "github.com/Megidy/BestLviv2026Test/internal/entity"

type GetAllInventoryFilter struct {
	LocationId       int    `param:"location_id" validate:"required"`
	ResourceName     string `query:"resource_name"`
	ResourceCategory string `query:"resource_category"`
	Limit            int
	Offset           int
}

type InventoryUnit struct {
	Inventory entity.Inventory `json:"inventory"`
	Resource  entity.Resource  `json:"resource"`
}
type GetAllInventoryResponse struct {
	InventoryUnits []InventoryUnit `json:"inventory_units"`
	Total          int             `json:"total"`
}
