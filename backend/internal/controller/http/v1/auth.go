package v1

import (
	"context"
	"log/slog"
	"net/http"

	"github.com/Megidy/BestLviv2026Test/internal/dto"
	"github.com/Megidy/BestLviv2026Test/internal/dto/httprequest"
	"github.com/Megidy/BestLviv2026Test/internal/dto/httpresponse"
	"github.com/Megidy/BestLviv2026Test/internal/entity"
	"github.com/labstack/echo/v5"
)

type authUseCase interface {
	Login(ctx context.Context, username, password string) (string, error)
	GetById(ctx context.Context, id int) (entity.User, error)
}
type AuthController struct {
	logger      *slog.Logger
	authUseCase authUseCase
}

func NewAuthController(logger *slog.Logger, authUseCase authUseCase) *AuthController {
	l := logger.WithGroup("auth_controller")
	return &AuthController{
		logger:      l,
		authUseCase: authUseCase,
	}
}

// Login godoc
// @Summary      User login
// @Description  Authenticates a user using username and password, returning a JWT token for further requests.
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Param        request  body      httprequest.Login  true  "Login credentials"
// @Success      200      {object}  httpresponse.Response{Data=string} "Successfully authenticated, returns JWT token"
// @Failure      400      {object}  httpresponse.Response{} "Bad Request - Invalid credentials or validation error"
// @Failure      500      {object}  httpresponse.Response{} "Internal Server Error"
// @Router       /v1/auth/login [post]
func (c *AuthController) Login(ctx *echo.Context) error {
	var req httprequest.Login

	l := c.logger.With("method", "login", "username", req.Username)
	err := ctx.Bind(&req)
	if err != nil {
		l.Warn("failed to parse request", "error", err)
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, err.Error())
	}

	err = ctx.Validate(req)
	if err != nil {
		l.Warn("failed to validate request", "error", err)
		return httpresponse.NewErrorResponse(ctx, entity.ErrBadRequest, err.Error())
	}

	token, err := c.authUseCase.Login(ctx.Request().Context(), req.Username, req.Password)
	if err != nil {
		l.Error("failed to login", "error", err)
		return httpresponse.NewErrorResponse(ctx, err, "failed to login")
	}

	return httpresponse.NewSuccessResponse(ctx, token, http.StatusOK)
}

// GetMe godoc
// @Summary      Get current user profile
// @Description  Retrieves the details of the currently authenticated user using the provided JWT token.
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200      {object}  httpresponse.Response{Data=entity.User} "Successfully retrieved user profile"
// @Failure      401      {object}  httpresponse.Response{} "Unauthorized - Invalid or missing token"
// @Failure      500      {object}  httpresponse.Response{} "Internal Server Error"
// @Router       /v1/auth/me [get]
func (c *AuthController) GetMe(ctx *echo.Context) error {
	userClaims := ctx.Get(entity.UserKey).(dto.UserClaims)

	l := c.logger.With("method", "get_me", "user", userClaims)

	user, err := c.authUseCase.GetById(ctx.Request().Context(), userClaims.UserID)
	if err != nil {
		l.Error("failed to get user by id", "error", err)
		return httpresponse.NewErrorResponse(ctx, err, "failed to get user by id")
	}

	return httpresponse.NewSuccessResponse(ctx, user, http.StatusOK)
}
