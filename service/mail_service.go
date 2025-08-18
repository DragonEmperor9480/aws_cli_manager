package service

import (
	"fmt"

	"gopkg.in/gomail.v2"
)

func MailService(username, to, accessKey, secretKey string) {
	m := gomail.NewMessage()
	password := ""

	m.SetHeader("From", "amruteshnaregal1234@gmail.com")
	m.SetHeader("To", to)
	m.SetHeader("Subject", "AWS Credentials")

	body := fmt.Sprintf(
		"Hi %s,\nYour AWS credentials are as follows:\n\nAccess Key: %s\nSecret Key: %s \n\n Test mail from AWS Manager",
		username, accessKey, secretKey,
	)
	m.SetBody("text/plain", body)

	d := gomail.NewDialer("smtp.gmail.com", 587, "amruteshnaregal1234@gmail.com", password)

	if err := d.DialAndSend(m); err != nil {
		fmt.Println("Error sending email:", err.Error())
		return
	}

	fmt.Println("Email sent successfully.")
}
