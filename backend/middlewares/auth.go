package middlewares

import (
	"context"
	"net/http"
	"strings"

	"allinone-backend/config"
	"allinone-backend/utils"

	"github.com/gin-gonic/gin"
)

// AuthMiddleware 验证JWT令牌并提取用户ID
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取Authorization头
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "未提供授权令牌"})
			c.Abort()
			return
		}

		// 检查Bearer前缀
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "授权格式无效"})
			c.Abort()
			return
		}

		tokenString := parts[1]

		// 检查token是否在黑名单中
		exists, err := config.RDB.Exists(context.Background(), "token_blacklist:"+tokenString).Result()
		if err == nil && exists > 0 {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "令牌已失效"})
			c.Abort()
			return
		}

		// 解析JWT令牌
		claims, err := utils.ParseJWT(tokenString)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "无效的令牌"})
			c.Abort()
			return
		}

		// 将用户ID存储在上下文中
		c.Set("user_id", uint(claims.UserID))
		c.Next()
	}
}
