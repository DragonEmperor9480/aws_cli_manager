package utils

import (
	"context"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatchlogs"
	"github.com/aws/aws-sdk-go-v2/service/iam"
	"github.com/aws/aws-sdk-go-v2/service/lambda"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

var (
	IAMClient    *iam.Client
	LogsClient   *cloudwatchlogs.Client
	LambdaClient *lambda.Client
	S3Client     *s3.Client
)

// InitAWSClients initializes AWS SDK clients
func InitAWSClients() error {
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		return err
	}

	IAMClient = iam.NewFromConfig(cfg)
	LogsClient = cloudwatchlogs.NewFromConfig(cfg)
	LambdaClient = lambda.NewFromConfig(cfg)
	S3Client = s3.NewFromConfig(cfg)
	return nil
}

// GetIAMClient returns the IAM client
func GetIAMClient() *iam.Client {
	return IAMClient
}

// GetLogsClient returns the CloudWatch Logs client
func GetLogsClient() *cloudwatchlogs.Client {
	return LogsClient
}

// GetLambdaClient returns the Lambda client
func GetLambdaClient() *lambda.Client {
	return LambdaClient
}

// GetS3Client returns the S3 client
func GetS3Client() *s3.Client {
	return S3Client
}
