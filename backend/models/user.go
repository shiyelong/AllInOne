package models

import (
	"errors"
	"sync"
	"time"

	"golang.org/x/crypto/bcrypt"
)

// User represents the user model
type User struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Email     string    `json:"email"`
	Phone     string    `json:"phone"`
	Username  string    `json:"username"`
	Password  string    `json:"password"`
	CreatedAt time.Time `json:"created_at"`
}

// LoginRequest represents login form data
type LoginRequest struct {
	Type     string `json:"type"` // phone, email, username
	Account  string `json:"account"`
	Password string `json:"password,omitempty"`
	Code     string `json:"code,omitempty"`
}

// RegisterRequest represents registration form data
type RegisterRequest struct {
	Type     string `json:"type"` // phone, email, username
	Account  string `json:"account"`
	Password string `json:"password"`
	Code     string `json:"code"`
}

// UserStore 是用户存储的接口
type UserStore interface {
	Save(user *User) error
	FindByID(id uint) (*User, error)
	FindByEmail(email string) (*User, error)
	FindByPhone(phone string) (*User, error)
	FindByUsername(username string) (*User, error)
}

// InMemoryUserStore 内存中的用户存储实现
type InMemoryUserStore struct {
	users     map[uint]*User
	emails    map[string]uint
	phones    map[string]uint
	usernames map[string]uint
	nextID    uint
	mutex     sync.RWMutex
}

var (
	// 全局单例用户存储
	userStore *InMemoryUserStore
	once      sync.Once
)

// GetUserStore 获取用户存储单例
func GetUserStore() *InMemoryUserStore {
	once.Do(func() {
		userStore = &InMemoryUserStore{
			users:     make(map[uint]*User),
			emails:    make(map[string]uint),
			phones:    make(map[string]uint),
			usernames: make(map[string]uint),
			nextID:    1,
		}
		// 预填充一个测试用户
		testUser := &User{
			ID:        1,
			Username:  "test",
			Email:     "test@example.com",
			Phone:     "13800138000",
			CreatedAt: time.Now(),
		}
		hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
		testUser.Password = string(hashedPassword)
		userStore.users[1] = testUser
		userStore.emails["test@example.com"] = 1
		userStore.phones["13800138000"] = 1
		userStore.usernames["test"] = 1
		userStore.nextID = 2
	})
	return userStore
}

// Save 保存用户
func (store *InMemoryUserStore) Save(user *User) error {
	store.mutex.Lock()
	defer store.mutex.Unlock()

	if user.ID == 0 {
		// 检查唯一性
		if user.Email != "" {
			if _, exists := store.emails[user.Email]; exists {
				return errors.New("邮箱已被注册")
			}
		}
		if user.Phone != "" {
			if _, exists := store.phones[user.Phone]; exists {
				return errors.New("手机号已被注册")
			}
		}
		if user.Username != "" {
			if _, exists := store.usernames[user.Username]; exists {
				return errors.New("用户名已被使用")
			}
		}

		// 分配新ID
		user.ID = store.nextID
		store.nextID++
		user.CreatedAt = time.Now()
	}

	// 存储用户
	store.users[user.ID] = user

	// 更新索引
	if user.Email != "" {
		store.emails[user.Email] = user.ID
	}
	if user.Phone != "" {
		store.phones[user.Phone] = user.ID
	}
	if user.Username != "" {
		store.usernames[user.Username] = user.ID
	}

	return nil
}

// FindByID 通过ID查找用户
func (store *InMemoryUserStore) FindByID(id uint) (*User, error) {
	store.mutex.RLock()
	defer store.mutex.RUnlock()

	if user, exists := store.users[id]; exists {
		return user, nil
	}
	return nil, errors.New("用户不存在")
}

// FindByEmail 通过邮箱查找用户
func (store *InMemoryUserStore) FindByEmail(email string) (*User, error) {
	store.mutex.RLock()
	defer store.mutex.RUnlock()

	if id, exists := store.emails[email]; exists {
		return store.users[id], nil
	}
	return nil, errors.New("用户不存在")
}

// FindByPhone 通过手机号查找用户
func (store *InMemoryUserStore) FindByPhone(phone string) (*User, error) {
	store.mutex.RLock()
	defer store.mutex.RUnlock()

	if id, exists := store.phones[phone]; exists {
		return store.users[id], nil
	}
	return nil, errors.New("用户不存在")
}

// FindByUsername 通过用户名查找用户
func (store *InMemoryUserStore) FindByUsername(username string) (*User, error) {
	store.mutex.RLock()
	defer store.mutex.RUnlock()

	if id, exists := store.usernames[username]; exists {
		return store.users[id], nil
	}
	return nil, errors.New("用户不存在")
}

// AuthenticateUser 根据登录类型、账号和密码验证用户
func AuthenticateUser(loginType, account, password string) (*User, error) {
	store := GetUserStore()
	var user *User
	var err error

	switch loginType {
	case "email":
		user, err = store.FindByEmail(account)
	case "phone":
		user, err = store.FindByPhone(account)
	case "username":
		user, err = store.FindByUsername(account)
	default:
		return nil, errors.New("无效的登录类型")
	}

	if err != nil {
		return nil, err
	}

	// 验证密码
	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password))
	if err != nil {
		return nil, errors.New("密码错误")
	}

	return user, nil
}

// RegisterUser 注册新用户
func RegisterUser(registerType, account, password string) (*User, error) {
	store := GetUserStore()

	// 检查是否已经存在
	var exists bool
	switch registerType {
	case "email":
		_, err := store.FindByEmail(account)
		exists = err == nil
	case "phone":
		_, err := store.FindByPhone(account)
		exists = err == nil
	case "username":
		_, err := store.FindByUsername(account)
		exists = err == nil
	default:
		return nil, errors.New("无效的注册类型")
	}

	if exists {
		return nil, errors.New("账号已存在")
	}

	// 创建新用户
	user := &User{
		CreatedAt: time.Now(),
	}

	// 设置账号
	switch registerType {
	case "email":
		user.Email = account
	case "phone":
		user.Phone = account
	case "username":
		user.Username = account
	}

	// 哈希密码
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, errors.New("密码加密失败")
	}
	user.Password = string(hashedPassword)

	// 保存用户
	if err := store.Save(user); err != nil {
		return nil, err
	}

	return user, nil
}
