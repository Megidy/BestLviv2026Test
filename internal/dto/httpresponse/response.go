package httpresponse

import (
	"time"

	"github.com/labstack/echo/v5"
)

type Response struct {
	Data     any              `json:"data,omitempty"`
	Metadata ResponseMetadata `json:"metadata"`
}

type ResponseMetadata struct {
	Err        string    `json:"error,omitempty"`
	Msg        string    `json:"message,omitempty"`
	StatusCode int       `json:"status_code"`
	Timestamp  time.Time `json:"timestamp"`
}

func NewResponseMetadata(statusCode int, err string) ResponseMetadata {
	return ResponseMetadata{
		StatusCode: statusCode,
		Err:        err,
		Timestamp:  time.Now().UTC(),
	}
}

func NewSuccessResponse(ctx *echo.Context, data any, statusCode int) error {
	resp := &Response{
		Data: data,
		Metadata: ResponseMetadata{
			StatusCode: statusCode,
			Timestamp:  time.Now().UTC(),
		},
	}

	return ctx.JSON(statusCode, resp)
}

func NewErrorResponse(ctx *echo.Context, err error, msg ...string) error {
	metadata := MapErrorToMetadata(err)
	var respMsg string
	if len(msg) > 0 {
		respMsg = msg[0]
	}
	metadata.Msg = respMsg

	resp := &Response{
		Metadata: metadata,
	}
	return ctx.JSON(resp.Metadata.StatusCode, resp)
}
