package middleware

import (
	"errors"
	"strings"

	"github.com/Megidy/BestLviv2026Test/internal/dto/httpresponse"
	"github.com/Megidy/BestLviv2026Test/internal/entity"
	"github.com/labstack/echo/v5"
)

const HeaderAuthorization = "Authorization"

func (m *Middleware) WithJWT() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c *echo.Context) error {
			l := m.logger.With("method", "with_jwt")
			authHeader := c.Request().Header.Get(HeaderAuthorization)
			if authHeader == "" {
				l.Warn("missing auth header")
				return httpresponse.NewErrorResponse(c, entity.ErrMissingAuthHeader)
			}

			parts := strings.Split(authHeader, " ")
			if len(parts) != 2 || parts[0] != "Bearer" {
				l.Warn("invalid auth token")
				return httpresponse.NewErrorResponse(c, entity.ErrInvalidToken)
			}

			tokenString := parts[1]

			claims, err := m.authUseCase.Validate(c.Request().Context(), tokenString)
			if err != nil {
				if errors.Is(err, entity.ErrInvalidToken) {
					l.Warn("invalid token", "error", err)
				} else {
					l.Error("failed to validate token", "error", err)
				}

				return httpresponse.NewErrorResponse(c, err, "failed to validate token")
			}

			c.Set(entity.UserKey, claims)

			return next(c)
		}
	}
}
