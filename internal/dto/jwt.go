package dto

import "github.com/golang-jwt/jwt/v5"

type UserClaims struct {
	UserID     int    `json:"user_id"`
	Username   string `json:"username"`
	Role       string `json:"role"`
	LocationID int    `json:"location_id"`
	jwt.RegisteredClaims
}
