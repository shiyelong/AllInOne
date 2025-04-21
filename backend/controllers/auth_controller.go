package controllers

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"allinone-backend/config"
	"allinone-backend/models"
	"allinone-backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
)

// User represents the user model for authentication
// This is a placeholder and should be replaced with the actual model from the models package
type User struct {
	ID        uint      `json:"id"`
	Email     string    `json:"email"`
	Password  string    `json:"password"`
	CreatedAt time.Time `json:"created_at"`
}

// JWTSecret is the secret key used for signing JWT tokens
var JWTSecret = []byte("your_secret_key")

// 二维码登录状态枚举
const (
	QRCodeStatusPending   = "pending"   // 等待扫描
	QRCodeStatusScanned   = "scanned"   // 已扫描
	QRCodeStatusConfirmed = "confirmed" // 已确认
	QRCodeStatusExpired   = "expired"   // 已过期
)

// 二维码登录会话数据
type QRCodeSession struct {
	SessionID  string    `json:"sessionId"`
	UserID     uint      `json:"userId,omitempty"`
	QRCode     string    `json:"qrCode"`
	Status     string    `json:"status"`
	ExpireTime time.Time `json:"expireTime"`
}

// Register handles user registration
func Register(c *gin.Context) {
	var registerData models.RegisterRequest
	if err := c.ShouldBindJSON(&registerData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的请求格式"})
		return
	}

	// 验证验证码 (实际场景中可能会根据type类型验证不同的验证码)
	// TODO: 实现验证码验证逻辑

	// 注册用户
	user, err := models.RegisterUser(registerData.Type, registerData.Account, registerData.Password)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 生成JWT令牌
	token, err := utils.GenerateJWT(int(user.ID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "生成令牌失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "注册成功",
		"token":   token,
		"user": gin.H{
			"id":         user.ID,
			"email":      user.Email,
			"phone":      user.Phone,
			"username":   user.Username,
			"created_at": user.CreatedAt,
		},
	})
}

// Login handles user login
func Login(c *gin.Context) {
	var loginData models.LoginRequest
	if err := c.ShouldBindJSON(&loginData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的请求格式"})
		return
	}

	var user *models.User
	var err error

	// 根据登录类型选择验证方式
	if loginData.Password != "" {
		// 密码登录
		user, err = models.AuthenticateUser(loginData.Type, loginData.Account, loginData.Password)
	} else if loginData.Code != "" {
		// 验证码登录
		// TODO: 实现验证码登录逻辑
		c.JSON(http.StatusNotImplemented, gin.H{"error": "验证码登录功能尚未实现"})
		return
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
		c.JSON(http.StatusInternalServerError, gin.H{"error": "生成令牌失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token": token,
		"user": gin.H{
			"id":         user.ID,
			"email":      user.Email,
			"phone":      user.Phone,
			"username":   user.Username,
			"created_at": user.CreatedAt,
		},
	})
}

// 生成二维码
func GenerateQRCode(c *gin.Context) {
	// 生成唯一的会话ID
	sessionID, err := generateRandomString(32)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "生成会话ID失败"})
		return
	}

	// 生成二维码数据 (实际上是一个包含sessionID的JSON字符串)
	qrCode := "qrlogin:" + sessionID

	// 创建二维码会话并存储到Redis
	qrSession := QRCodeSession{
		SessionID:  sessionID,
		QRCode:     qrCode,
		Status:     QRCodeStatusPending,
		ExpireTime: time.Now().Add(5 * time.Minute), // 5分钟有效期
	}

	// 将会话数据序列化为JSON
	sessionJSON, err := json.Marshal(qrSession)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "序列化会话数据失败"})
		return
	}

	// 存储到Redis
	err = config.RDB.Set(context.Background(), "qrcode:"+sessionID, string(sessionJSON), 5*time.Minute).Err()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "存储会话数据失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"sessionId": sessionID,
		"qrCode":    qrCode,
		"expireIn":  300, // 5分钟，单位秒
	})
}

// 检查二维码状态
func CheckQRCodeStatus(c *gin.Context) {
	sessionID := c.Query("sessionId")
	if sessionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "会话ID不能为空"})
		return
	}

	// 从Redis获取会话数据
	sessionData, err := config.RDB.Get(context.Background(), "qrcode:"+sessionID).Result()
	if err != nil {
		if err == redis.Nil {
			c.JSON(http.StatusNotFound, gin.H{"status": QRCodeStatusExpired})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "获取会话数据失败"})
		}
		return
	}

	// 解析会话数据
	var qrSession QRCodeSession
	err = json.Unmarshal([]byte(sessionData), &qrSession)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "解析会话数据失败"})
		return
	}

	// 检查是否过期
	if time.Now().After(qrSession.ExpireTime) {
		c.JSON(http.StatusOK, gin.H{"status": QRCodeStatusExpired})
		return
	}

	// 返回状态
	response := gin.H{"status": qrSession.Status}

	// 如果已确认，返回令牌
	if qrSession.Status == QRCodeStatusConfirmed && qrSession.UserID > 0 {
		// 生成令牌
		token, err := utils.GenerateJWT(int(qrSession.UserID))
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "生成令牌失败"})
			return
		}
		response["token"] = token

		// 删除会话数据，防止重复使用
		config.RDB.Del(context.Background(), "qrcode:"+sessionID)
	}

	c.JSON(http.StatusOK, response)
}

// 扫描二维码
func ScanQRCode(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未登录"})
		return
	}

	// 获取二维码
	var req struct {
		QRCode string `json:"qrCode"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的请求"})
		return
	}

	// 解析二维码
	if len(req.QRCode) < 9 || req.QRCode[:8] != "qrlogin:" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的二维码"})
		return
	}

	sessionID := req.QRCode[8:]

	// 从Redis获取会话数据
	sessionData, err := config.RDB.Get(context.Background(), "qrcode:"+sessionID).Result()
	if err != nil {
		if err == redis.Nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "二维码已过期或不存在"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "获取会话数据失败"})
		}
		return
	}

	// 解析会话数据
	var qrSession QRCodeSession
	err = json.Unmarshal([]byte(sessionData), &qrSession)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "解析会话数据失败"})
		return
	}

	// 检查是否过期
	if time.Now().After(qrSession.ExpireTime) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "二维码已过期"})
		return
	}

	// 检查状态
	if qrSession.Status != QRCodeStatusPending {
		c.JSON(http.StatusBadRequest, gin.H{"error": "二维码已被使用"})
		return
	}

	// 更新状态
	qrSession.Status = QRCodeStatusScanned
	qrSession.UserID = userID.(uint)

	// 更新Redis
	updatedSessionJSON, err := json.Marshal(qrSession)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "序列化会话数据失败"})
		return
	}

	expiration := qrSession.ExpireTime.Sub(time.Now())
	err = config.RDB.Set(context.Background(), "qrcode:"+sessionID, string(updatedSessionJSON), expiration).Err()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "更新会话数据失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":   "扫描成功",
		"sessionId": sessionID,
	})
}

// 确认登录
func ConfirmQRLogin(c *gin.Context) {
	// 获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未登录"})
		return
	}

	// 获取会话ID
	var req struct {
		SessionID string `json:"sessionId"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的请求"})
		return
	}

	// 从Redis获取会话数据
	sessionData, err := config.RDB.Get(context.Background(), "qrcode:"+req.SessionID).Result()
	if err != nil {
		if err == redis.Nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "会话已过期或不存在"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "获取会话数据失败"})
		}
		return
	}

	// 解析会话数据
	var qrSession QRCodeSession
	err = json.Unmarshal([]byte(sessionData), &qrSession)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "解析会话数据失败"})
		return
	}

	// 检查是否过期
	if time.Now().After(qrSession.ExpireTime) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "会话已过期"})
		return
	}

	// 检查状态
	if qrSession.Status != QRCodeStatusScanned {
		c.JSON(http.StatusBadRequest, gin.H{"error": "二维码状态错误"})
		return
	}

	// 检查是否是同一用户
	if qrSession.UserID != userID.(uint) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "用户不匹配"})
		return
	}

	// 更新状态
	qrSession.Status = QRCodeStatusConfirmed

	// 更新Redis
	updatedSessionJSON, err := json.Marshal(qrSession)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "序列化会话数据失败"})
		return
	}

	expiration := qrSession.ExpireTime.Sub(time.Now())
	err = config.RDB.Set(context.Background(), "qrcode:"+req.SessionID, string(updatedSessionJSON), expiration).Err()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "更新会话数据失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "登录已确认"})
}

// SendCode 发送验证码
func SendCode(c *gin.Context) {
	type Req struct {
		Type    string `json:"type"` // phone/email
		Account string `json:"account"`
	}

	var req Req
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的请求"})
		return
	}

	// 生成6位验证码
	code := utils.GenerateVerifyCode(6)

	// 在实际应用中，这里应该有发送短信或邮件的逻辑
	// 此处为了演示，我们只把验证码存到Redis
	key := req.Type + ":" + req.Account + ":code"

	// 存储验证码到Redis，有效期5分钟
	if err := utils.SetVerifyCode(config.RDB, key, code, 5*time.Minute); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "存储验证码失败"})
		return
	}

	// 仅开发环境下直接返回验证码
	isDev := true // TODO: 从配置中获取环境标识
	if isDev {
		c.JSON(http.StatusOK, gin.H{
			"message": "验证码已发送",
			"code":    code, // 仅开发环境返回
		})
	} else {
		c.JSON(http.StatusOK, gin.H{
			"message": "验证码已发送",
		})
	}
}

// VerifyCode 验证验证码
func VerifyCode(c *gin.Context) {
	type Req struct {
		Type    string `json:"type"`
		Account string `json:"account"`
		Code    string `json:"code"`
	}

	var req Req
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的请求"})
		return
	}

	// 验证码键名
	key := req.Type + ":" + req.Account + ":code"

	// 校验验证码
	if utils.CheckVerifyCode(config.RDB, key, req.Code) {
		// 验证通过后，删除验证码防止重用
		config.RDB.Del(context.Background(), key)
		c.JSON(http.StatusOK, gin.H{
			"valid":   true,
			"message": "验证码正确",
		})
	} else {
		c.JSON(http.StatusBadRequest, gin.H{
			"valid": false,
			"error": "验证码错误或已过期",
		})
	}
}

// 绑定邮箱
func BindEmail(c *gin.Context) {
	type Req struct {
		UserID uint   `json:"user_id"`
		Email  string `json:"email"`
	}
	var req Req
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}
	// TODO: 实际应查库并更新用户邮箱
	c.JSON(http.StatusOK, gin.H{"message": "邮箱绑定成功", "email": req.Email})
}

// 启用2FA
func Enable2FA(c *gin.Context) {
	type Req struct {
		UserID uint `json:"user_id"`
	}
	var req Req
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}
	// TODO: 生成2FA密钥并保存
	secret := "2fa-secret-demo" // 示例
	c.JSON(http.StatusOK, gin.H{"secret": secret})
}

// 校验2FA
func Verify2FA(c *gin.Context) {
	type Req struct {
		UserID uint   `json:"user_id"`
		Code   string `json:"code"`
	}
	var req Req
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}
	// TODO: 校验2FA code
	if req.Code == "123456" { // 示例
		c.JSON(http.StatusOK, gin.H{"message": "2FA 验证成功"})
	} else {
		c.JSON(http.StatusBadRequest, gin.H{"error": "2FA 验证失败"})
	}
}

// 登录历史
func GetLoginHistory(c *gin.Context) {
	// TODO: 查询登录历史
	history := []gin.H{
		{"time": "2025-04-21 10:00", "ip": "127.0.0.1"},
	}
	c.JSON(http.StatusOK, gin.H{"history": history})
}

// 设备管理
func GetDevices(c *gin.Context) {
	// TODO: 查询设备列表
	devices := []gin.H{
		{"id": 1, "name": "iPhone 15", "login_time": "2025-04-21 10:00"},
	}
	c.JSON(http.StatusOK, gin.H{"devices": devices})
}

func LogoutDevice(c *gin.Context) {
	type Req struct {
		DeviceID uint `json:"device_id"`
	}
	var req Req
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}
	// TODO: 注销设备
	c.JSON(http.StatusOK, gin.H{"message": "设备已登出"})
}

// 忘记密码
func ForgotPassword(c *gin.Context) {
	type Req struct {
		Type        string `json:"type"` // phone/email
		Account     string `json:"account"`
		Code        string `json:"code"`
		NewPassword string `json:"newPassword"`
	}
	var req Req
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}

	// 验证码校验
	key := "verify_code:" + req.Type + ":" + req.Account
	if !utils.CheckVerifyCode(config.RDB, key, req.Code) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "验证码错误"})
		return
	}

	// TODO: 更新用户密码
	// 1. 查找用户
	// 2. 更新密码
	// 3. 保存到数据库

	c.JSON(http.StatusOK, gin.H{"message": "密码重置成功"})
}

// Logout 用户登出
func Logout(c *gin.Context) {
	// 获取授权头
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "未提供授权令牌"})
		return
	}

	// 提取令牌
	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "授权格式无效"})
		return
	}

	tokenString := parts[1]

	// 解析令牌以获取过期时间
	claims, err := utils.ParseJWT(tokenString)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "无效的令牌"})
		return
	}

	// 计算令牌剩余有效期
	expirationTime := claims.ExpiresAt.Time
	duration := time.Until(expirationTime)
	if duration < 0 {
		// 如果令牌已过期，直接返回成功
		c.JSON(http.StatusOK, gin.H{"message": "登出成功"})
		return
	}

	// 将令牌添加到黑名单，有效期与令牌剩余有效期相同
	err = config.RDB.Set(context.Background(), "token_blacklist:"+tokenString, "1", duration).Err()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "登出失败，请重试"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "登出成功"})
}

// 生成随机字符串
func generateRandomString(length int) (string, error) {
	b := make([]byte, length)
	_, err := rand.Read(b)
	if err != nil {
		return "", err
	}
	return base64.URLEncoding.EncodeToString(b)[:length], nil
}
