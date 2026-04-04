package middleware

import (
	"time"

	"github.com/labstack/echo/v5"
)

func (m *Middleware) RequestLogger() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c *echo.Context) error {
			start := time.Now()
			err := next(c)
			req := c.Request()
			res := c.Response()
			m.logger.Info("request",
				"method", req.Method,
				"path", req.URL.Path,
				"status", res.Status,
				"latency_ms", time.Since(start).Milliseconds(),
				"ip", c.RealIP(),
			)
			return err
		}
	}
}
