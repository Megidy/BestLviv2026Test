package auth

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/Megidy/BestLviv2026Test/internal/entity"
)

type stubUserRepo struct {
	userByUsername   entity.User
	userByID         entity.User
	getByUsernameErr error
	getByIDErr       error
}

func (s *stubUserRepo) GetByUsername(ctx context.Context, username string) (entity.User, error) {
	if s.getByUsernameErr != nil {
		return entity.User{}, s.getByUsernameErr
	}
	return s.userByUsername, nil
}

func (s *stubUserRepo) GetById(ctx context.Context, id int) (entity.User, error) {
	if s.getByIDErr != nil {
		return entity.User{}, s.getByIDErr
	}
	return s.userByID, nil
}

func (s *stubUserRepo) Create(ctx context.Context, user entity.User) (int, error) {
	return 0, nil
}

func TestLoginAndValidate(t *testing.T) {
	t.Parallel()

	repo := &stubUserRepo{}
	uc := New("secret-key", time.Hour, repo)

	hash, err := uc.HashPassword("correct-password")
	if err != nil {
		t.Fatalf("HashPassword() error = %v", err)
	}

	repo.userByUsername = entity.User{
		Id:           42,
		Username:     "alice",
		PasswordHash: hash,
		Role:         entity.UserRoleDispatcher,
		WarehouseId:  7,
	}

	token, err := uc.Login(context.Background(), "alice", "correct-password")
	if err != nil {
		t.Fatalf("Login() error = %v", err)
	}
	if token == "" {
		t.Fatal("Login() returned an empty token")
	}

	claims, err := uc.Validate(context.Background(), token)
	if err != nil {
		t.Fatalf("Validate() error = %v", err)
	}

	if claims.UserID != 42 {
		t.Fatalf("Validate() user id = %d, want 42", claims.UserID)
	}
	if claims.Username != "alice" {
		t.Fatalf("Validate() username = %q, want alice", claims.Username)
	}
	if claims.Role != entity.UserRoleDispatcher {
		t.Fatalf("Validate() role = %q, want %q", claims.Role, entity.UserRoleDispatcher)
	}
	if claims.WarehouseId != 7 {
		t.Fatalf("Validate() location id = %d, want 7", claims.WarehouseId)
	}
	if claims.ExpiresAt == nil || claims.ExpiresAt.Time.Before(time.Now()) {
		t.Fatal("Validate() returned claims without a future expiration")
	}
}

func TestLoginReturnsInvalidCredentialsForUnknownUserOrWrongPassword(t *testing.T) {
	t.Parallel()

	t.Run("repo miss", func(t *testing.T) {
		t.Parallel()

		repo := &stubUserRepo{getByUsernameErr: entity.ErrUserNotFound}
		uc := New("secret-key", time.Hour, repo)

		_, err := uc.Login(context.Background(), "alice", "secret")
		if !errors.Is(err, entity.ErrInvalidCredentials) {
			t.Fatalf("Login() error = %v, want %v", err, entity.ErrInvalidCredentials)
		}
	})

	t.Run("wrong password", func(t *testing.T) {
		t.Parallel()

		repo := &stubUserRepo{}
		uc := New("secret-key", time.Hour, repo)

		hash, err := uc.HashPassword("correct-password")
		if err != nil {
			t.Fatalf("HashPassword() error = %v", err)
		}
		repo.userByUsername = entity.User{
			Id:           42,
			Username:     "alice",
			PasswordHash: hash,
		}

		_, err = uc.Login(context.Background(), "alice", "wrong-password")
		if !errors.Is(err, entity.ErrInvalidCredentials) {
			t.Fatalf("Login() error = %v, want %v", err, entity.ErrInvalidCredentials)
		}
	})
}

func TestValidateRejectsTamperedToken(t *testing.T) {
	t.Parallel()

	repo := &stubUserRepo{}
	uc := New("secret-key", time.Hour, repo)

	hash, err := uc.HashPassword("correct-password")
	if err != nil {
		t.Fatalf("HashPassword() error = %v", err)
	}
	repo.userByUsername = entity.User{
		Id:           42,
		Username:     "alice",
		PasswordHash: hash,
		Role:         entity.UserRoleWorker,
	}

	token, err := uc.Login(context.Background(), "alice", "correct-password")
	if err != nil {
		t.Fatalf("Login() error = %v", err)
	}

	_, err = uc.Validate(context.Background(), token+"tampered")
	if !errors.Is(err, entity.ErrInvalidToken) {
		t.Fatalf("Validate() error = %v, want %v", err, entity.ErrInvalidToken)
	}
}
