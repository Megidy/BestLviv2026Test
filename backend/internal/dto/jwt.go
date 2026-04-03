package dto

import (
	"github.com/Megidy/BestLviv2026Test/internal/entity"
	"github.com/golang-jwt/jwt/v5"
)

type UserClaims struct {
	UserID      int             `json:"user_id"`
	Username    string          `json:"username"`
	Role        entity.UserRole `json:"role"`
	WarehouseId int             `json:"warehouse_id"`
	jwt.RegisteredClaims
}
