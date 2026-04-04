package middleware

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v5"
)

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(code int) {
	r.status = code
	r.ResponseWriter.WriteHeader(code)
}

func (m *Middleware) RequestLogger() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c *echo.Context) error {
			rec := &statusRecorder{ResponseWriter: c.Response(), status: http.StatusOK}
			c.SetResponse(rec)
			start := time.Now()
			err := next(c)
			m.logger.Info("request",
				"method", c.Request().Method,
				"path", c.Request().URL.Path,
				"status", rec.status,
				"latency_ms", time.Since(start).Milliseconds(),
				"ip", c.RealIP(),
			)
			return err
		}
	}
}
