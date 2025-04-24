package utils

import (
	"context"
	"crypto/rand"
	"fmt"
	"math/big"
	"strconv"
	"time"

	"github.com/go-redis/redis/v8"
)

// GenerateVerifyCode generates a numeric verification code of given length
// 使用更安全的随机数生成方法
func GenerateVerifyCode(length int) string {
	code := ""
	for i := 0; i < length; i++ {
		// 使用crypto/rand包生成更安全的随机数
		num, err := rand.Int(rand.Reader, big.NewInt(10))
		if err != nil {
			// 如果安全随机数生成失败，回退到不太安全的方法
			code += strconv.Itoa(int(time.Now().UnixNano() % 10))
		} else {
			code += num.String()
		}
	}
	return code
}

// SetVerifyCode stores the verification code in Redis with expiration
func SetVerifyCode(rdb *redis.Client, key, code string, expire time.Duration) error {
	return rdb.Set(context.Background(), key, code, expire).Err()
}

// CheckVerifyCode validates the verification code and deletes it on success
func CheckVerifyCode(rdb *redis.Client, key, code string) bool {
	val, err := rdb.Get(context.Background(), key).Result()
	if err != nil || val != code {
		return false
	}
	rdb.Del(context.Background(), key)
	return true
}

// GetCodeKey 生成验证码的Redis键名
func GetCodeKey(codeType, account string) string {
	return fmt.Sprintf("%s:%s:code", codeType, account)
}

// GetCodeExpiration 获取验证码的过期时间
func GetCodeExpiration() time.Duration {
	return 5 * time.Minute
}

// GetRemainingTime 获取验证码的剩余有效时间
func GetRemainingTime(rdb *redis.Client, key string) (time.Duration, error) {
	return rdb.TTL(context.Background(), key).Result()
}

// IsCodeExists 检查验证码是否已存在且未过期
func IsCodeExists(rdb *redis.Client, key string) bool {
	ttl, err := rdb.TTL(context.Background(), key).Result()
	if err != nil || ttl <= 0 {
		return false
	}
	return true
}
