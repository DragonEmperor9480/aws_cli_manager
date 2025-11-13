package utils

import (
	"context"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/iam"
)

var IAMClient *iam.Client

// InitAWSClients initializes AWS SDK clients
func InitAWSClients() error {
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		return err
	}

	IAMClient = iam.NewFromConfig(cfg)
	return nil
}
