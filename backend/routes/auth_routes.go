package routes

import (
	"allinone-backend/controllers"
	"allinone-backend/middlewares"

	"github.com/gin-gonic/gin"
)

func AuthRoutes(router *gin.Engine) {
	authGroup := router.Group("/auth")
	{
		authGroup.POST("/login", controllers.Login)
		authGroup.POST("/register", controllers.Register)
		authGroup.POST("/send_code", controllers.SendCode)
		authGroup.POST("/verify_code", controllers.VerifyCode)
		authGroup.POST("/bind_email", controllers.BindEmail)
		authGroup.POST("/2fa/enable", controllers.Enable2FA)
		authGroup.POST("/2fa/verify", controllers.Verify2FA)
		authGroup.GET("/login_history", controllers.GetLoginHistory)
		authGroup.GET("/devices", controllers.GetDevices)
		authGroup.POST("/devices/logout", controllers.LogoutDevice)
		authGroup.POST("/forgot_password", controllers.ForgotPassword)
		authGroup.POST("/logout", controllers.Logout)

		// 二维码登录相关路由
		qrcodeGroup := authGroup.Group("/qrcode")
		{
			qrcodeGroup.GET("/generate", controllers.GenerateQRCode)
			qrcodeGroup.GET("/check", controllers.CheckQRCodeStatus)

			// 需要认证的路由
			authQrGroup := qrcodeGroup.Group("/")
			authQrGroup.Use(middlewares.AuthMiddleware())
			{
				authQrGroup.POST("/scan", controllers.ScanQRCode)
				authQrGroup.POST("/confirm", controllers.ConfirmQRLogin)
			}
		}
	}
}
