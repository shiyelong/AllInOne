package controllers

import (
	"AllInOne/backend/config"
	"AllInOne/backend/models"
	"AllInOne/backend/utils"
	"fmt"
	"net/http"
	"net/smtp"
	"os"

	// "time"

	"github.com/gin-gonic/gin"
)

// SendCode sends a verification code to phone or email
type codeRequest struct {
	Type    string `json:"type"` // "email" or "phone"
	Account string `json:"account"`
}

// SendCode sends a verification code via email or phone (simulated)
func SendCode(c *gin.Context) {
	var req codeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效请求"})
		return
	}

	// 验证账号类型
	if req.Type != "email" && req.Type != "phone" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "不支持的验证码类型"})
		return
	}

	// 使用工具函数生成标准化的键名
	key := utils.GetCodeKey(req.Type, req.Account)

	// 检查是否存在未过期的验证码
	if utils.IsCodeExists(config.RDB, key) {
		remaining, _ := utils.GetRemainingTime(config.RDB, key)
		c.JSON(http.StatusTooManyRequests, gin.H{
			"error":   "验证码已发送",
			"message": fmt.Sprintf("请等待 %d 秒后重试", int(remaining.Seconds())),
		})
		return
	}

	// 生成6位数字验证码
	code := utils.GenerateVerifyCode(6)

	// 获取标准过期时间并将验证码存储到Redis
	expiration := utils.GetCodeExpiration()
	if err := utils.SetVerifyCode(config.RDB, key, code, expiration); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "验证码存储失败"})
		return
	}

	// 根据类型发送验证码
	switch req.Type {
	case "email":
		// 发送邮箱验证码
		host := os.Getenv("SMTP_HOST")
		port := os.Getenv("SMTP_PORT")
		user := os.Getenv("SMTP_USER")
		pass := os.Getenv("SMTP_PASS")

		// 检查SMTP配置
		if host == "" || port == "" || user == "" || pass == "" {
			c.JSON(http.StatusOK, gin.H{
				"message": "验证码已生成（测试模式）",
				"code":    code, // 仅在测试环境返回验证码
				"note":    "SMTP未配置，实际环境中不会返回验证码",
			})
			return
		}

		auth := smtp.PlainAuth("", user, pass, host)
		msg := []byte("Subject: 您的验证码\r\n\r\n您的验证码是: " + code + "，有效期5分钟。")
		if err := smtp.SendMail(host+":"+port, auth, user, []string{req.Account}, msg); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "邮件发送失败"})
			return
		}

	case "phone":
		// 手机验证码发送（模拟）
		// 实际项目中，这里应该集成短信服务商的API
		// 目前仅作为预留功能，返回成功并在测试环境中显示验证码
		c.JSON(http.StatusOK, gin.H{
			"message": "验证码已生成（测试模式）",
			"code":    code, // 仅在测试环境返回验证码
			"note":    "短信服务未集成，实际环境中不会返回验证码",
		})
		return

	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "不支持的验证码类型"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "验证码已发送"})
}

// VerifyCode verifies a received code
type verifyRequest struct {
	Type    string `json:"type"`
	Account string `json:"account"`
	Code    string `json:"code"`
}

func VerifyCode(c *gin.Context) {
	var req verifyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效请求"})
		return
	}

	// 验证账号类型
	if req.Type != "email" && req.Type != "phone" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "不支持的验证码类型"})
		return
	}

	// 使用工具函数生成标准化的键名
	key := utils.GetCodeKey(req.Type, req.Account)

	// 验证验证码
	if !utils.CheckVerifyCode(config.RDB, key, req.Code) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "验证码无效或已过期"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "验证码有效"})
}

// Register registers a new user with password
type registerRequest models.RegisterRequest

func Register(c *gin.Context) {
	var req registerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效请求"})
		return
	}

	// 验证账号类型
	if req.Type != "email" && req.Type != "phone" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "不支持的账号类型"})
		return
	}

	// 使用工具函数生成标准化的键名
	key := utils.GetCodeKey(req.Type, req.Account)

	// 验证验证码
	if !utils.CheckVerifyCode(config.RDB, key, req.Code) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "验证码无效或已过期"})
		return
	}
	user, err := models.RegisterUser(req.Type, req.Account, req.Password)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	token, err := utils.GenerateJWT(int(user.ID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "registration successful", "token": token, "user": user})
}

// Login logs in a user via password or code
func Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效请求"})
		return
	}

	// 验证账号类型
	if req.Type != "email" && req.Type != "phone" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "不支持的账号类型"})
		return
	}

	var user *models.User
	var err error

	// 根据登录方式处理
	if req.Password != "" {
		// 密码登录
		user, err = models.AuthenticateUser(req.Type, req.Account, req.Password)
	} else if req.Code != "" {
		// 验证码登录
		key := utils.GetCodeKey(req.Type, req.Account)
		if !utils.CheckVerifyCode(config.RDB, key, req.Code) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "验证码无效或已过期"})
			return
		}
		// 验证码正确，查找或创建用户（一键登录注册）
		user, err = models.FindOrCreateUser(req.Type, req.Account)
	} else {
		c.JSON(http.StatusBadRequest, gin.H{"error": "请提供密码或验证码"})
		return
	}

	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	// 生成JWT令牌
	token, err := utils.GenerateJWT(int(user.ID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "令牌生成失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "登录成功",
		"token":   token,
		"user":    user,
	})
}
