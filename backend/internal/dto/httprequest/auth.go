package httprequest

import "github.com/Megidy/BestLviv2026Test/internal/entity"

type Login struct {
	Username string `json:"username" validate:"required"`
	Password string `json:"password" validate:"required"`
}

type CreateUser struct {
	Username    string          `json:"username" validate:"required"`
	Password    string          `json:"required" validate:"required"`
	Role        entity.UserRole `json:"role" validate:"required,oneof=worker dispatcher"`
	WarehouseId int             `json:"warehouse_id"`
}
