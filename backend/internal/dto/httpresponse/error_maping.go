package httpresponse

import (
	"errors"
	"net/http"

	"github.com/Megidy/BestLviv2026Test/internal/entity"
)

var errorToMetadata = map[error]ResponseMetadata{
	entity.ErrBadRequest:              NewResponseMetadata(http.StatusBadRequest, entity.ErrBadRequest.Error()),
	entity.ErrMissingAuthHeader:       NewResponseMetadata(http.StatusUnauthorized, entity.ErrMissingAuthHeader.Error()),
	entity.ErrInvalidCredentials:      NewResponseMetadata(http.StatusUnauthorized, entity.ErrInvalidCredentials.Error()),
	entity.ErrInvalidToken:            NewResponseMetadata(http.StatusUnauthorized, entity.ErrInvalidToken.Error()),
	entity.ErrUserNotFound:            NewResponseMetadata(http.StatusNotFound, entity.ErrUserNotFound.Error()),
	entity.ErrInvalidPaginationParams: NewResponseMetadata(http.StatusBadRequest, entity.ErrBadRequest.Error()),
	entity.ErrNotFound:                NewResponseMetadata(http.StatusNotFound, entity.ErrNotFound.Error()),
	entity.ErrNoSuppliersAvailable:    NewResponseMetadata(http.StatusUnprocessableEntity, entity.ErrNoSuppliersAvailable.Error()),
	entity.ErrAlreadyResolved:         NewResponseMetadata(http.StatusConflict, entity.ErrAlreadyResolved.Error()),
}

func MapErrorToMetadata(err error) ResponseMetadata {
	if err == nil {
		return NewResponseMetadata(
			http.StatusInternalServerError,
			http.StatusText(http.StatusInternalServerError),
		)
	}

	for domainErr, metadata := range errorToMetadata {
		if errors.Is(err, domainErr) {
			return metadata
		}
	}

	return NewResponseMetadata(
		http.StatusInternalServerError,
		err.Error(),
	)
}
