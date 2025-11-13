package db_service

// SaveMFADevice saves or updates the single MFA device in the database
func SaveMFADevice(deviceName, deviceARN string) error {
	// Delete any existing MFA device (we only store one)
	DB.Where("1 = 1").Delete(&MFADevice{})

	// Create new device
	device := MFADevice{
		DeviceName: deviceName,
		DeviceARN:  deviceARN,
	}

	result := DB.Create(&device)
	return result.Error
}

// GetMFADevice retrieves the stored MFA device
func GetMFADevice() (*MFADevice, error) {
	var device MFADevice
	result := DB.First(&device)
	if result.Error != nil {
		return nil, result.Error
	}
	return &device, nil
}

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

// UpdateUserPassword updates the password for a user
func UpdateUserPassword(username, newPassword string) error {
	encPassword, err := Encrypt(newPassword)
	if err != nil {
		return err
	}

	result := DB.Model(&UserCredential{}).Where("username = ?", username).Update("password", encPassword)
	return result.Error
}
