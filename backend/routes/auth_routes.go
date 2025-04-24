package routes

import (
	"AllInOne/backend/controllers"

	"github.com/gin-gonic/gin"
)

// AuthRoutes registers authentication routes
func AuthRoutes(r *gin.Engine) {
	a := r.Group("/auth")
	{
		a.POST("/send_code", controllers.SendCode)
		a.POST("/verify_code", controllers.VerifyCode)
		a.POST("/register", controllers.Register)
		a.POST("/login", controllers.Login)
	}
}
