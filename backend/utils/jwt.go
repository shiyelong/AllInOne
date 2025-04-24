package utils

import (
	"errors"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v4"
)

// getJWTSecret retrieves the JWT secret from environment
func getJWTSecret() []byte {
	if s := os.Getenv("JWT_SECRET"); s != "" {
		return []byte(s)
	}
	return []byte("default_secret_key")
}

// Claims defines JWT claims
type Claims struct {
	UserID int `json:"user_id"`
	jwt.RegisteredClaims
}

// GenerateJWT creates a JWT token for a user
func GenerateJWT(userID int) (string, error) {
	exp := time.Now().Add(24 * time.Hour)
	claims := Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(exp),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	t := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return t.SignedString(getJWTSecret())
}

// ParseJWT parses and validates a JWT token
func ParseJWT(tokenString string) (*Claims, error) {
	claims := &Claims{}
	tok, err := jwt.ParseWithClaims(tokenString, claims, func(tok *jwt.Token) (interface{}, error) {
		return getJWTSecret(), nil
	})
	if err != nil || !tok.Valid {
		return nil, errors.New("无效的令牌")
	}
	return claims, nil
}
