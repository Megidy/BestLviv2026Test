package entity

import "time"

type UserRole string
type User struct {
	Id           int      `json:"id"`
	Username     string   `json:"username"`
	PasswordHash string   `json:"-"`
	Role         UserRole `json:"role"`
	WarehouseId  int      `json:"location_id"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
