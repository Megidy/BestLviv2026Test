package middleware

import (
	"strconv"

	"github.com/Megidy/BestLviv2026Test/internal/dto/httpresponse"
	"github.com/Megidy/BestLviv2026Test/internal/entity"
	"github.com/labstack/echo/v5"
)

const (
	Page        = "page"
	PageSize    = "pageSize"
	MaxPageSize = 50
)

func (m *Middleware) WithPagination() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c *echo.Context) error {
			l := m.logger.With("method", "with_pagination")
			page := c.QueryParam(Page)
			pageSize := c.QueryParam(PageSize)
			if page == "" || pageSize == "" {
				l.Warn("page or page size are invalid")
				return httpresponse.NewErrorResponse(c, entity.ErrInvalidPaginationParams, "page or page size are empty")
			}

			pageInt, err := strconv.Atoi(page)
			if err != nil {
				l.Warn("failed to convert page to int", "error", err)
				return httpresponse.NewErrorResponse(c, entity.ErrInvalidPaginationParams, err.Error())
			}

			pageSizeInt, err := strconv.Atoi(pageSize)
			if err != nil {
				l.Warn("failed to convert page size", "error", err)
				return httpresponse.NewErrorResponse(c, entity.ErrInvalidPaginationParams, err.Error())
			}

			if pageInt <= 0 || pageSizeInt <= 0 {
				l.Warn("page or page size are below zero")
				return httpresponse.NewErrorResponse(c, entity.ErrInvalidPaginationParams, "page or page size are below zero")
			}

			if pageSizeInt > MaxPageSize {
				l.Warn("page size is greater than 50")
				return httpresponse.NewErrorResponse(c, entity.ErrInvalidPaginationParams, "page size is greater than 50")
			}
			limit := pageSizeInt
			offset := (pageInt - 1) * limit

			c.Set(entity.LimitKey, limit)
			c.Set(entity.OffsetKey, offset)

			return next(c)
		}
	}
}
