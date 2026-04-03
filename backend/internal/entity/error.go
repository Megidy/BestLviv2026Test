package entity

import "errors"

var (
	ErrBadRequest               = errors.New("bad request")
	ErrMissingAuthHeader        = errors.New("missing auth header")
	ErrInvalidCredentials       = errors.New("invalid username or password")
	ErrInvalidToken             = errors.New("invalid token")
	ErrUserNotFound             = errors.New("user not found")
	ErrInvalidPaginationParams  = errors.New("invalid pagination params")
	ErrNotFound                 = errors.New("not found")
	ErrNoSuppliersAvailable     = errors.New("no suppliers available for rebalancing")
	ErrAlreadyResolved          = errors.New("alert or proposal already resolved")
	ErrForbidden                = errors.New("forbidden")
	ErrInvalidStatusTransition  = errors.New("invalid status transition")
	ErrInsufficientStock        = errors.New("insufficient stock to fully satisfy request")
)
