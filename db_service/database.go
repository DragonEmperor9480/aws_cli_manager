package db_service

import (
	"os"
	"path/filepath"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

var DB *gorm.DB

// InitDB initializes the database connection
func InitDB() error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return err
	}

	dbPath := filepath.Join(homeDir, ".awsmgr", "awsmgr_data.db")

	// Create directory if it doesn't exist
	os.MkdirAll(filepath.Dir(dbPath), 0700)

	// Open database
	DB, err = gorm.Open(sqlite.Open(dbPath), &gorm.Config{})
	if err != nil {
		return err
	}

	// Auto-migrate schema
	err = DB.AutoMigrate(&UserCredential{})
	if err != nil {
		return err
	}

	// Set file permissions to owner only
	os.Chmod(dbPath, 0600)

	return nil
}
