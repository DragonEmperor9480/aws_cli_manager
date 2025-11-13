package db_service

// SaveUserCredential saves or updates a user credential in the database
func SaveUserCredential(username, password string) error {
	// Encrypt password
	encPassword, err := Encrypt(password)
	if err != nil {
		return err
	}

	credential := UserCredential{
		Username: username,
		Password: encPassword,
	}

	// Upsert (update if exists, insert if not)
	result := DB.Where("username = ?", username).Assign(credential).FirstOrCreate(&credential)
	return result.Error
}

// GetUserCredential retrieves a user credential by username
func GetUserCredential(username string) (*UserCredential, error) {
	var credential UserCredential
	result := DB.Where("username = ?", username).First(&credential)
	if result.Error != nil {
		return nil, result.Error
	}

	// Decrypt password
	if credential.Password != "" {
		decPassword, err := Decrypt(credential.Password)
		if err != nil {
			return nil, err
		}
		credential.Password = decPassword
	}

	return &credential, nil
}

// ListAllUserCredentials retrieves all stored user credentials
func ListAllUserCredentials() ([]UserCredential, error) {
	var credentials []UserCredential
	result := DB.Find(&credentials)
	if result.Error != nil {
		return nil, result.Error
	}

	// Decrypt passwords for display
	for i := range credentials {
		if credentials[i].Password != "" {
			decPassword, err := Decrypt(credentials[i].Password)
			if err == nil {
				credentials[i].Password = decPassword
			}
		}
	}

	return credentials, nil
}

// DeleteUserCredential deletes a user credential by username
func DeleteUserCredential(username string) error {
	result := DB.Where("username = ?", username).Delete(&UserCredential{})
	return result.Error
}

// UpdateUserPassword updates the password for a user
func UpdateUserPassword(username, newPassword string) error {
	encPassword, err := Encrypt(newPassword)
	if err != nil {
		return err
	}

	result := DB.Model(&UserCredential{}).Where("username = ?", username).Update("password", encPassword)
	return result.Error
}
