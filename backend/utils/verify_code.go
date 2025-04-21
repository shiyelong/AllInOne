package utils

import (
	"context"
	"math/rand"
	"strconv"
	"time"

	"github.com/go-redis/redis/v8"
)

var ctx = context.Background()

// GenerateVerifyCode 生成指定长度的数字验证码
func GenerateVerifyCode(length int) string {
	rand.Seed(time.Now().UnixNano())
	code := ""
	for i := 0; i < length; i++ {
		code += strconv.Itoa(rand.Intn(10))
	}
	return code
}

// SetVerifyCode 存储验证码到 Redis
func SetVerifyCode(rdb *redis.Client, key, code string, expire time.Duration) error {
	return rdb.Set(ctx, key, code, expire).Err()
}

// CheckVerifyCode 校验验证码
func CheckVerifyCode(rdb *redis.Client, key, code string) bool {
	val, err := rdb.Get(ctx, key).Result()
	if err != nil {
		return false
	}
	return val == code
}
