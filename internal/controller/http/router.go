package controller

import (
	"net/http"

	_ "github.com/Megidy/BestLviv2026Test/docs"
	v1 "github.com/Megidy/BestLviv2026Test/internal/controller/http/v1"
	"github.com/Megidy/BestLviv2026Test/internal/controller/http/v1/middleware"
	"github.com/Megidy/BestLviv2026Test/internal/dto/httprequest"
	"github.com/labstack/echo/v5"
	echoSwagger "github.com/swaggo/echo-swagger/v2"
)

// Swagger spec:
// @title Best Lviv api docs
// @version 1.0
// @description swagger documentation.
// @version     1.0

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and JWT token, "Bearer <token>".

type Router struct {
	e *echo.Echo

	middleware          *middleware.Middleware
	authController      *v1.AuthController
	inventoryController *v1.InventoryController

	validator *httprequest.CustomValidator
}

func NewRouter(
	e *echo.Echo,
	middleware *middleware.Middleware,
	authController *v1.AuthController,
	inventoryController *v1.InventoryController,
	validator *httprequest.CustomValidator,
) *Router {
	return &Router{
		e: e,

		middleware:          middleware,
		authController:      authController,
		inventoryController: inventoryController,

		validator: validator,
	}
}

func (r *Router) RegisterRoutes() {
	r.e.GET("/health", func(c *echo.Context) error { return c.JSON(http.StatusOK, map[string]string{"status": "healthy"}) })
	r.e.GET("/swagger/*", echoSwagger.WrapHandlerV3)

	r.e.Validator = r.validator
	v1 := r.e.Group("/v1")

	withJWT := r.middleware.WithJWT()
	withPagination := r.middleware.WithPagination()
	{
		auth := v1.Group("/auth")
		auth.POST("/login", r.authController.Login)
		auth.GET("/me", r.authController.GetMe, withJWT)

	}

	{
		inventory := v1.Group("/inventory", withJWT)
		inventory.GET("/:location_id", r.inventoryController.GetAll, withPagination)
		// inventory.PUT("/:location_id", nil)
	}
}
