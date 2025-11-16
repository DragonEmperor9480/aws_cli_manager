package policy

import (
	"github.com/DragonEmperor9480/aws_cli_manager/models/iam/policy"
)

// ListPoliciesController lists all IAM policies
func ListPoliciesController(scope string) ([]policy.Policy, error) {
	return policy.ListPoliciesModel(scope)
}
