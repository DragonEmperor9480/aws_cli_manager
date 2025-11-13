package db_service

import (
	"log"
	"os"
	"path/filepath"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
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

	// Open database with silent logger to suppress "record not found" errors
	DB, err = gorm.Open(sqlite.Open(dbPath), &gorm.Config{
		Logger: logger.New(
			log.New(os.Stdout, "\r\n", log.LstdFlags),
			logger.Config{
				LogLevel: logger.Silent, // Suppress all logs including "record not found"
			},
		),
	})
	if err != nil {
		return err
	}

	// Auto-migrate schema
	err = DB.AutoMigrate(&UserCredential{}, &MFADevice{})
	if err != nil {
		return err
	}

	// Set file permissions to owner only
	os.Chmod(dbPath, 0600)

	return nil
}
