package auth

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"

	"github.com/Megidy/BestLviv2026Test/internal/dto"
	"github.com/Megidy/BestLviv2026Test/internal/entity"
)

type UserRepo interface {
	GetByUsername(ctx context.Context, username string) (entity.User, error)
	GetById(ctx context.Context, id int) (entity.User, error)
	Create(ctx context.Context, user entity.User) (int, error)
}

type UseCase struct {
	jwtSecret   []byte
	jwtDuration time.Duration
	userRepo    UserRepo
}

func New(jwtSecret string, jwtDuration time.Duration, userRepo UserRepo) *UseCase {
	return &UseCase{
		jwtSecret:   []byte(jwtSecret),
		jwtDuration: jwtDuration,
		userRepo:    userRepo,
	}
}

func (u *UseCase) Login(ctx context.Context, username, password string) (string, error) {
	user, err := u.userRepo.GetByUsername(ctx, username)
	if err != nil {
		return "", entity.ErrInvalidCredentials
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password))
	if err != nil {
		if errors.Is(err, bcrypt.ErrMismatchedHashAndPassword) {
			return "", entity.ErrInvalidCredentials
		}
		return "", err
	}

	expirationTime := time.Now().Add(u.jwtDuration)
	claims := &dto.UserClaims{
		UserID:      user.Id,
		Username:    user.Username,
		Role:        user.Role,
		WarehouseId: user.WarehouseId,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	tokenString, err := token.SignedString(u.jwtSecret)
	if err != nil {
		return "", err
	}

	return tokenString, nil
}

func (u *UseCase) Validate(ctx context.Context, tokenString string) (dto.UserClaims, error) {
	claims := dto.UserClaims{}

	token, err := jwt.ParseWithClaims(tokenString, &claims, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, entity.ErrInvalidToken
		}
		return u.jwtSecret, nil
	})

	if err != nil {
		return dto.UserClaims{}, fmt.Errorf("%w: %w", entity.ErrInvalidToken, err)
	}

	if !token.Valid {
		return dto.UserClaims{}, entity.ErrInvalidToken
	}

	return claims, nil
}

func (u *UseCase) Create(ctx context.Context, username, password string, warehouseId int, role entity.UserRole) error {
	hashedPassword, err := u.HashPassword(password)
	if err != nil {
		return fmt.Errorf("failed to hash password: %w", err)
	}

	user := entity.User{
		Username:     username,
		PasswordHash: hashedPassword,
		Role:         role,
		WarehouseId:  warehouseId,
	}

	_, err = u.userRepo.Create(ctx, user)
	if err != nil {
		return fmt.Errorf("failed to create user: %w", err)
	}

	return nil
}

func (u *UseCase) GetById(ctx context.Context, id int) (entity.User, error) {
	return u.userRepo.GetById(ctx, id)
}

func (u *UseCase) HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 12)
	return string(bytes), err
}
