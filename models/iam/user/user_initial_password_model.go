package user

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/db_service"
	"github.com/DragonEmperor9480/aws_cli_manager/utils"
)

func SetInitialUserPasswordModel(username, password string) {
	reader := bufio.NewReader(os.Stdin)
	fmt.Print(utils.Yellow + utils.Bold + "Allow password reset at first login? (y/n): " + utils.Reset)
	choice, _ := reader.ReadString('\n')
	choice = strings.ToLower(strings.TrimSpace(choice))

	utils.ShowProcessingAnimation("Processing...")

	var cmd *exec.Cmd
	if choice == "y" {
		fmt.Println(utils.Bold + utils.Yellow + "Initial password reset is enabled." + utils.Reset)
		cmd = exec.Command("aws", "iam", "create-login-profile", "--user-name", username, "--password", password, "--password-reset-required")
	} else {
		fmt.Println(utils.Bold + utils.Yellow + "Initial password reset is disabled." + utils.Reset)
		cmd = exec.Command("aws", "iam", "create-login-profile", "--user-name", username, "--password", password)
	}

	outputBytes, _ := cmd.CombinedOutput()
	output := string(outputBytes)
	utils.StopAnimation()
	if strings.Contains(output, "UserName") && strings.Contains(output, "CreateDate") {
		fmt.Println(utils.Green + utils.Bold + " User password created successfully!" + utils.Reset)
	} else if strings.Contains(output, "NoSuchEntity") {
		fmt.Println(utils.Red + utils.Bold + "Error: The user '" + username + "' does not exist!" + utils.Reset)
		return
	} else if strings.Contains(output, "PasswordPolicyViolation") {
		fmt.Println(utils.Red + utils.Bold + "Error: Password does not meet AWS policy requirements!" + utils.Reset)
		fmt.Println(utils.Yellow + "Password should include at least:\n" +
			"- One uppercase letter\n" +
			"- One lowercase letter\n" +
			"- One symbol (e.g., !@#$%^&*)\n" +
			"- One number (if required by your policy)\n" +
			"- Minimum length as per your account policy" + utils.Reset)
		return
	} else if strings.Contains(output, "EntityAlreadyExists") {
		fmt.Println(utils.Red + utils.Bold + "Error: The Password for the user '" + username + "'already exists!" + utils.Reset)
		return
	} else {
		fmt.Println(utils.Red + utils.Bold + "Error occurred while creating password:" + utils.Reset)
		fmt.Println(output)
		return
	}

	//Save credentials
	fmt.Print(utils.Yellow + utils.Bold + "Would you like to save " + username + "'s credentials? (y/n): " + utils.Reset)
	saveChoice, _ := reader.ReadString('\n')
	saveChoice = strings.ToLower(strings.TrimSpace(saveChoice))

	if saveChoice == "y" {
		err := db_service.SaveUserCredential(username, password)
		if err != nil {
			fmt.Println(utils.Red + utils.Bold + "Error saving credentials: " + err.Error() + utils.Reset)
			return
		}
		fmt.Println(utils.Green + utils.Bold + "✓ Credentials saved securely to database" + utils.Reset)
	}

	// Show credentials
	fmt.Println(utils.Cyan + utils.Bold + "\nGenerated Credentials:" + utils.Reset)
	fmt.Println("Username: " + utils.Bold + username + utils.Reset)
	fmt.Println("Password: " + utils.Bold + password + utils.Reset)
}
