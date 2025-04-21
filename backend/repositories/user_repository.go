package repositories

import (
	"allinone-backend/models"

	"gorm.io/gorm"
)

// UserRepository handles user-related database operations
type UserRepository struct {
	DB *gorm.DB
}

// CreateUser creates a new user in the database
func (repo *UserRepository) CreateUser(user *models.User) error {
	return repo.DB.Create(user).Error
}

// GetUserByEmail retrieves a user by email
func (repo *UserRepository) GetUserByEmail(email string) (*models.User, error) {
	var user models.User
	if err := repo.DB.Where("email = ?", email).First(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}
