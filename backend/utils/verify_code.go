package utils

import (
    "context"
    "math/rand"
    "strconv"
    "time"

    "github.com/go-redis/redis/v8"
)

// GenerateVerifyCode generates a numeric verification code of given length
func GenerateVerifyCode(length int) string {
    rand.Seed(time.Now().UnixNano())
    code := ""
    for i := 0; i < length; i++ {
        code += strconv.Itoa(rand.Intn(10))
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
