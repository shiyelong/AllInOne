package controllers

import (
	"AllInOne/backend/config"
	"AllInOne/backend/models"
	"AllInOne/backend/utils"
	"net/http"
	"net/smtp"
	"os"
	"time"

	"github.com/gin-gonic/gin"
)

// SendCode sends a verification code to phone or email
type codeRequest struct {
	Type    string `json:"type"` // "email" or "phone"
	Account string `json:"account"`
}

// SendCode sends a verification code via email; phone codes are disabled
func SendCode(c *gin.Context) {
	var req codeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	if req.Type != "email" {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "手机验证码暂未开放"})
		return
	}
	code := utils.GenerateVerifyCode(6)
	key := req.Type + ":" + req.Account + ":code"
	if err := utils.SetVerifyCode(config.RDB, key, code, 5*time.Minute); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to store code"})
		return
	}
	// SMTP email sending
	host := os.Getenv("SMTP_HOST")
	port := os.Getenv("SMTP_PORT")
	user := os.Getenv("SMTP_USER")
	pass := os.Getenv("SMTP_PASS")
	auth := smtp.PlainAuth("", user, pass, host)
	msg := []byte("Subject: 您的验证码\r\n\r\n您的验证码是: " + code + "，有效期5分钟。")
	if err := smtp.SendMail(host+":"+port, auth, user, []string{req.Account}, msg); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "邮件发送失败"})
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
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	key := req.Type + ":" + req.Account + ":code"
	if !utils.CheckVerifyCode(config.RDB, key, req.Code) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid or expired code"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "code valid"})
}

// Register registers a new user with password
type registerRequest models.RegisterRequest

func Register(c *gin.Context) {
	var req registerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	key := req.Type + ":" + req.Account + ":code"
	if !utils.CheckVerifyCode(config.RDB, key, req.Code) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid or expired code"})
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
type loginRequest models.LoginRequest

func Login(c *gin.Context) {
	var req loginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}
	var user *models.User
	var err error
	if req.Password != "" {
		user, err = models.AuthenticateUser(req.Type, req.Account, req.Password)
	} else if req.Code != "" {
		key := req.Type + ":" + req.Account + ":code"
		if !utils.CheckVerifyCode(config.RDB, key, req.Code) {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid or expired code"})
			return
		}
		user, err = models.FindOrCreateUser(req.Type, req.Account)
	} else {
		c.JSON(http.StatusBadRequest, gin.H{"error": "provide password or code"})
		return
	}
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	token, err := utils.GenerateJWT(int(user.ID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"token": token, "user": user})
}
