package cfg

import (
	"fmt"
	"time"

	"github.com/caarlos0/env/v11"
	"github.com/joho/godotenv"
)

type Api struct {
	LogLevel       string `env:"LOG_LEVEL,required"`
	HttpServerPort string `env:"HTTP_SERVER_PORT,required"`
	Environment    string `env:"ENVIRONMENT,required"`

	JWTSecret   string        `env:"JWT_SECRET,required"`
	JwtDuration time.Duration `env:"JWT_DURATION,required"`

	PostgresConnectionURI   string        `env:"POSTGRES_CONNECTION_URI,required"`
	PostgresMaxConns        int           `env:"POSTGRES_MAX_CONNS,required"`
	PostgresMinConns        int           `env:"POSTGRES_MIN_CONNS,required"`
	PostgresMaxConnLifetime time.Duration `env:"POSTGRES_MAX_CONN_LIFETIME,required"`
	PostgresMaxConnIdleTime time.Duration `env:"POSTGRES_MAX_CONN_IDLE_TIME,required"`
}

func New[Service Api]() (*Service, error) {
	godotenv.Load()
	cfg := new(Service)
	if err := env.Parse(cfg); err != nil {
		return nil, fmt.Errorf("failed to parse env: %w", err)
	}

	return cfg, nil
}
