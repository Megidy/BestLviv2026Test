package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/Megidy/BestLviv2026Test/internal/cfg"
	httprouter "github.com/Megidy/BestLviv2026Test/internal/controller/http"
	v1 "github.com/Megidy/BestLviv2026Test/internal/controller/http/v1"
	"github.com/Megidy/BestLviv2026Test/internal/controller/http/v1/middleware"
	"github.com/Megidy/BestLviv2026Test/internal/dto/httprequest"
	"github.com/Megidy/BestLviv2026Test/internal/repo/persistent"
	"github.com/Megidy/BestLviv2026Test/internal/pkg/groq"
	"github.com/Megidy/BestLviv2026Test/internal/usecase/auth"
	"github.com/Megidy/BestLviv2026Test/internal/usecase/deliveryrequest"
	"github.com/Megidy/BestLviv2026Test/internal/usecase/inventory"
	"github.com/Megidy/BestLviv2026Test/internal/usecase/mapview"
	"github.com/Megidy/BestLviv2026Test/internal/usecase/prediction"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v5"
)

func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	application, err := newApp(ctx)
	if err != nil {
		slog.Error("failed to initialize application", "error", err)
		os.Exit(1)
	}

	if err := application.Run(); err != nil {
		application.logger.Error("application stopped with error", "error", err)
		os.Exit(1)
	}
}

type app struct {
	ctx        context.Context
	cancelFunc context.CancelFunc
	cfg        *cfg.Api
	router     *echo.Echo
	db         *pgxpool.Pool
	logger     *slog.Logger
}

func newApp(ctx context.Context) (*app, error) {
	c, err := cfg.New()
	if err != nil {
		return nil, fmt.Errorf("failed to create config: %w", err)
	}

	if c.HttpServerPort[0] != ':' {
		c.HttpServerPort = ":" + c.HttpServerPort
	}

	logger := setupLogger(c.LogLevel)
	slog.SetDefault(logger)

	e := echo.New()

	pool, err := setupPostgresConnPool(ctx, c)
	if err != nil {
		return nil, fmt.Errorf("failed to create postgres conn pool: %w", err)
	}
	logger.Info("successfully connected to the database")

	// Repos
	userRepo := persistent.NewUserRepo(pool)
	inventoryRepo := persistent.NewInventoryRepo(pool)
	aiRepo := persistent.NewAIRepo(pool)
	deliveryRepo := persistent.NewDeliveryRepo(pool)
	auditRepo := persistent.NewAuditRepo(pool)
	mapRepo := persistent.NewMapRepo(pool)

	// Use cases
	authUseCase := auth.New(c.JWTSecret, c.JwtDuration, userRepo)
	inventoryUseCase := inventory.New(inventoryRepo)
	var predictionUseCase *prediction.UseCase
	if c.GroqAPIKey != "" {
		logger.Info("Groq LLM rationale generation enabled", "model", c.GroqModel)
		predictionUseCase = prediction.New(aiRepo, groq.New(c.GroqAPIKey, c.GroqModel), logger)
	} else {
		predictionUseCase = prediction.New(aiRepo, nil, logger)
	}
	deliveryUseCase := deliveryrequest.New(deliveryRepo, auditRepo, logger)
	mapUseCase := mapview.New(mapRepo)

	// Controllers
	authController := v1.NewAuthController(logger, authUseCase)
	inventoryController := v1.NewInventoryController(logger, inventoryUseCase)
	predictionController := v1.NewPredictionController(logger, predictionUseCase)
	deliveryController := v1.NewDeliveryController(logger, deliveryUseCase)
	mapController := v1.NewMapController(logger, mapUseCase)

	mw := middleware.NewMiddleware(logger, authUseCase)
	validator, err := httprequest.NewCustomValidator()
	if err != nil {
		return nil, fmt.Errorf("failed to create new custom validator: %w", err)
	}

	router := httprouter.NewRouter(e, mw, authController, inventoryController, predictionController, deliveryController, mapController, validator)
	router.RegisterRoutes()

	appCtx, cancel := context.WithCancel(ctx)

	// Start background prediction loop
	go predictionUseCase.StartPredictionLoop(appCtx, c.PredictionInterval)

	return &app{
		ctx:        appCtx,
		cancelFunc: cancel,
		cfg:        c,
		router:     e,
		db:         pool,
		logger:     logger,
	}, nil
}

func (a *app) Run() error {
	serverErrCh := make(chan error, 1)

	go func() {
		sc := echo.StartConfig{Address: a.cfg.HttpServerPort}
		if err := sc.Start(a.ctx, a.router); err != nil {
			serverErrCh <- err
		}
	}()

	select {
	case <-a.ctx.Done():
		a.logger.Info("OS Interrupt/Termination signal received")
		return a.Shutdown()
	case err := <-serverErrCh:
		if errors.Is(err, http.ErrServerClosed) {
			return nil
		}
		return fmt.Errorf("echo server error: %w", err)
	}
}

func (a *app) Shutdown() error {
	a.logger.Info("Starting graceful shutdown...")
	a.cancelFunc()

	a.logger.Info("Closing database connection pool...")
	if a.db != nil {
		a.db.Close()
	}

	a.logger.Info("Graceful shutdown completed successfully")
	return nil
}

func setupLogger(levelStr string) *slog.Logger {
	var level slog.Level
	if err := level.UnmarshalText([]byte(levelStr)); err != nil {
		level = slog.LevelInfo
	}
	handler := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: level})
	return slog.New(handler)
}

func setupPostgresConnPool(ctx context.Context, c *cfg.Api) (*pgxpool.Pool, error) {
	poolConfig, err := pgxpool.ParseConfig(c.PostgresConnectionURI)
	if err != nil {
		return nil, fmt.Errorf("failed to parse config: %w", err)
	}

	poolConfig.MaxConns = int32(c.PostgresMaxConns)
	poolConfig.MinConns = int32(c.PostgresMinConns)
	poolConfig.MaxConnLifetime = c.PostgresMaxConnLifetime
	poolConfig.MaxConnIdleTime = c.PostgresMaxConnIdleTime

	const pingTimeout = time.Second * 10
	iCtx, cancel := context.WithTimeout(ctx, pingTimeout)
	defer cancel()

	pool, err := pgxpool.NewWithConfig(iCtx, poolConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create pool: %w", err)
	}

	if err = pool.Ping(iCtx); err != nil {
		return nil, fmt.Errorf("failed to ping connection: %w", err)
	}

	return pool, nil
}
