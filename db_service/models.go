package db_service

import "gorm.io/gorm"

// UserCredential stores IAM user credentials
type UserCredential struct {
	gorm.Model
	Username string `gorm:"uniqueIndex;not null"`
	Password string // Encrypted
}

// MFADevice stores MFA device information (only one device stored)
type MFADevice struct {
	gorm.Model
	DeviceName string `gorm:"not null"`
	DeviceARN  string `gorm:"not null"`
}
