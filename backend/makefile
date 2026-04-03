DB_URL := "postgres://postgres:password@localhost:5432/best?sslmode=disable"
MIGRATIONS_PATH := "migrations/dev"

start-deps:
	@docker compose -f docker-compose.deps.yaml up --build -d

start:
	@go run -race cmd/api/main.go

migrate-up:
	@migrate -path $(MIGRATIONS_PATH) -database $(DB_URL) up

migrate-down:
	@migrate -path $(MIGRATIONS_PATH) -database $(DB_URL) down -all

gen-swag:
	@swag init -g ./internal/controller/http/router.go

test:
	@go test ./... 