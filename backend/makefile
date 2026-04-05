DB_URL := "postgres://postgres:password@localhost:5432/best?sslmode=disable"
MIGRATIONS_PATH := "migrations/dev"
GOOS := $(shell go env GOOS)
CGO_ENABLED := $(shell go env CGO_ENABLED)

start-deps:
	@docker compose -f docker-compose.deps.yaml up --build -d

start:
ifeq ($(GOOS),windows)
	@go run cmd/api/main.go
else ifeq ($(CGO_ENABLED),1)
	@go run -race cmd/api/main.go
else
	@go run cmd/api/main.go
endif

migrate-up:
	@migrate -path $(MIGRATIONS_PATH) -database $(DB_URL) up

migrate-down:
	@migrate -path $(MIGRATIONS_PATH) -database $(DB_URL) down -all

gen-swag:
	@swag init -g ./internal/controller/http/router.go

test:
	@go test ./... 