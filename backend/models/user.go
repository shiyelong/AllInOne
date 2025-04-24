package models

import (
	"errors"
	"sync"
	"time"
	"golang.org/x/crypto/bcrypt"
)

// User represents a user account
type User struct {
	ID        uint      `json:"id"`
	Email     string    `json:"email,omitempty"`
	Phone     string    `json:"phone,omitempty"`
	Password  string    `json:"-"`
	CreatedAt time.Time `json:"created_at"`
}

// LoginRequest holds login input data
type LoginRequest struct {
	Type     string `json:"type"`
	Account  string `json:"account"`
	Password string `json:"password,omitempty"`
	Code     string `json:"code,omitempty"`
}

// RegisterRequest holds registration input data
type RegisterRequest struct {
	Type     string `json:"type"`
	Account  string `json:"account"`
	Password string `json:"password"`
	Code     string `json:"code"`
}

// UserStore defines storage interface for users
type UserStore interface {
	Save(user *User) error
	FindByEmail(email string) (*User, error)
	FindByPhone(phone string) (*User, error)
}

// InMemoryUserStore is a simple in-memory user store
type InMemoryUserStore struct {
	mutex  sync.RWMutex
	users  map[uint]*User
	emails map[string]uint
	phones map[string]uint
	nextID uint
}

var (
	store *InMemoryUserStore
	once  sync.Once
)

// GetUserStore returns singleton InMemoryUserStore
func GetUserStore() *InMemoryUserStore {
	once.Do(func() {
		store = &InMemoryUserStore{
			users:  make(map[uint]*User),
			emails: make(map[string]uint),
			phones: make(map[string]uint),
			nextID: 1,
		}
	})
	return store
}

// Save creates or updates a user
func (s *InMemoryUserStore) Save(user *User) error {
	s.mutex.Lock()
	defer s.mutex.Unlock()
	// new user
	if user.ID == 0 {
		// uniqueness check
		if user.Email != "" {
			if _, ok := s.emails[user.Email]; ok {
				return errors.New("邮箱已被注册")
			}
		}
		if user.Phone != "" {
			if _, ok := s.phones[user.Phone]; ok {
				return errors.New("手机号已被注册")
			}
		}
		user.ID = s.nextID
		s.nextID++
		user.CreatedAt = time.Now()
	}
	// store
	s.users[user.ID] = user
	if user.Email != "" {
		s.emails[user.Email] = user.ID
	}
	if user.Phone != "" {
		s.phones[user.Phone] = user.ID
	}
	return nil
}

// FindByEmail fetches a user by email
func (s *InMemoryUserStore) FindByEmail(email string) (*User, error) {
	s.mutex.RLock()
	defer s.mutex.RUnlock()
	if id, ok := s.emails[email]; ok {
		return s.users[id], nil
	}
	return nil, errors.New("用户不存在")
}

// FindByPhone fetches a user by phone
func (s *InMemoryUserStore) FindByPhone(phone string) (*User, error) {
	s.mutex.RLock()
	defer s.mutex.RUnlock()
	if id, ok := s.phones[phone]; ok {
		return s.users[id], nil
	}
	return nil, errors.New("用户不存在")
}

// AuthenticateUser validates credentials
func AuthenticateUser(loginType, account, password string) (*User, error) {
	store := GetUserStore()
	var user *User
	var err error
	switch loginType {
	case "email":
		user, err = store.FindByEmail(account)
	case "phone":
		user, err = store.FindByPhone(account)
	default:
		return nil, errors.New("无效的登录类型")
	}
	if err != nil {
		return nil, err
	}
	if bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password)) != nil {
		return nil, errors.New("密码错误")
	}
	return user, nil
}

// RegisterUser creates a new user with password
func RegisterUser(regType, account, password string) (*User, error) {
	store := GetUserStore()
	// existence check
	var exists bool
	switch regType {
	case "email":
		_, err := store.FindByEmail(account)
		exists = err == nil
	case "phone":
		_, err := store.FindByPhone(account)
		exists = err == nil
	default:
		return nil, errors.New("无效的注册类型")
	}
	if exists {
		return nil, errors.New("账号已存在")
	}
	// hash password
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, errors.New("密码加密失败")
	}
	user := &User{Password: string(hash)}
	switch regType {
	case "email":
		user.Email = account
	case "phone":
		user.Phone = account
	}
	if err := store.Save(user); err != nil {
		return nil, err
	}
	return user, nil
}

// FindOrCreateUser logs in by code, auto-register if missing
func FindOrCreateUser(loginType, account string) (*User, error) {
	store := GetUserStore()
	var user *User
	var err error
	switch loginType {
	case "email":
		user, err = store.FindByEmail(account)
	case "phone":
		user, err = store.FindByPhone(account)
	default:
		return nil, errors.New("无效的登录类型")
	}
	if err == nil {
		return user, nil
	}
	// create without password
	user = &User{}
	switch loginType {
	case "email":
		user.Email = account
	case "phone":
		user.Phone = account
	}
	if err := store.Save(user); err != nil {
		return nil, err
	}
	return user, nil
}
