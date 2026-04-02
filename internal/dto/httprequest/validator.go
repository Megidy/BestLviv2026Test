package httprequest

import (
	"github.com/go-playground/validator/v10"
)

type CustomValidator struct {
	validator *validator.Validate
}

func NewCustomValidator() (*CustomValidator, error) {
	v := validator.New()

	return &CustomValidator{
		validator: v,
	}, nil
}

func (cv *CustomValidator) Validate(i any) error {
	return cv.validator.Struct(i)
}
