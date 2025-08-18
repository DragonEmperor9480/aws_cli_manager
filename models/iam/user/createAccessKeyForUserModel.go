package user

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/service"
	iamview "github.com/DragonEmperor9480/aws_cli_manager/views/iam/user"
)

func CreateAccessKeyForUserModel(username string) {

	cond := UserExistsOrNotModel(username)
	if !cond {
		fmt.Println("User does not exist.")
		return
	}

	// Create access key for user
	createCmd := exec.Command("aws", "iam", "create-access-key", "--user-name", username)
	output, err := createCmd.CombinedOutput()
	if err != nil {
		fmt.Println("Error creating access key:", err)
		return
	}

	accessKey, secretAccessKey := iamview.ShowAccessKeyView(string(output))
	fmt.Println("Would you like to save the access key and secret access key? (y/n): ")
	reader := bufio.NewReader(os.Stdin)
	saveChoice, _ := reader.ReadString('\n')
	saveChoice = strings.ToLower(strings.TrimSpace(saveChoice))

	if saveChoice == "y" {
		// Save the access key and secret access key
		credentialsDir := "/home/" + os.Getenv("USER") + "/.config/awsmgr/user_AccessKey_Credentials"
		os.MkdirAll(credentialsDir, 0755)
		filePath := credentialsDir + "/" + username + "_access_key_credentials.txt"
		file, err := os.Create(filePath)
		if err != nil {
			fmt.Println("Error creating credentials file:", err)
			return
		}
		defer file.Close()

		_, err = file.WriteString(" User: " + username + "\n")
		if err != nil {
			fmt.Println("Error writing to credentials file:", err)
			return
		}
		_, err = file.WriteString("Access Key: " + accessKey + "\n")
		if err != nil {
			fmt.Println("Error writing to credentials file:", err)
			return
		}
		_, err = file.WriteString("Secret Access Key: " + secretAccessKey + "\n")
		if err != nil {
			fmt.Println("Error writing to credentials file:", err)
			return
		}
		fmt.Println("Access key and secret access key saved successfully at:", filePath)

	}

	fmt.Println("Would you like to Share these credentials to user via mail? (y/n): ")
	saveChoice, _ = reader.ReadString(' ')
	saveChoice = strings.ToLower(strings.TrimSpace(saveChoice))
	if saveChoice == "y" {
		fmt.Println("Enter User mail:")
		reciverMail, _ := reader.ReadString(' ')
		reciverMail = strings.TrimSpace(reciverMail)
		service.MailService(username, reciverMail, accessKey, secretAccessKey)
	}

}
