FROM golang:1.25-alpine AS builder

WORKDIR /app

# Cache dependencies separately from source
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o server ./cmd/api/main.go

# ----

FROM alpine:3.21

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app
COPY --from=builder /app/server .

EXPOSE 8080
CMD ["./server"]
