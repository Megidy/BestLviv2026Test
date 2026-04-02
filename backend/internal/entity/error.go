package entity

import "errors"

var (
	ErrBadRequest              = errors.New("bad request")
	ErrMissingAuthHeader       = errors.New("missing auth header")
	ErrInvalidCredentials      = errors.New("invalid username or password")
	ErrInvalidToken            = errors.New("invalid token")
	ErrUserNotFound            = errors.New("user not found")
	ErrInvalidPaginationParams = errors.New("invalid pagination params")
)
