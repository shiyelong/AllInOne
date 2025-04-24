package config

import (
	"context"
	"os"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/joho/godotenv"
)

// RDB is the global Redis client
var RDB *redis.Client

// InitRedis loads environment variables and initializes Redis client
func InitRedis() error {
	godotenv.Load()
	addr := os.Getenv("REDIS_URL")
	if addr == "" {
		addr = "localhost:6379"
	}
	RDB = redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: os.Getenv("REDIS_PASSWORD"),
		DB:       0,
	})
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_, err := RDB.Ping(ctx).Result()
	return err
}
