package main

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/DragonEmperor9480/aws_cli_manager/backend/api"
	"github.com/DragonEmperor9480/aws_cli_manager/db_service"
	"github.com/DragonEmperor9480/aws_cli_manager/utils"
	"github.com/gorilla/mux"
)

// CORS middleware
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Origin, Content-Type, Authorization")
		w.Header().Set("Access-Control-Expose-Headers", "Content-Length")
		w.Header().Set("Access-Control-Allow-Credentials", "true")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func main() {
	// Initialize database
	if err := db_service.InitDB(); err != nil {
		log.Fatal("Error initializing database:", err)
	}

	// Initialize AWS SDK clients
	if err := utils.InitAWSClients(); err != nil {
		log.Fatal("Error initializing AWS clients:", err)
	}

	r := mux.NewRouter()

	// IAM Users
	r.HandleFunc("/api/iam/users", api.ListIAMUsers).Methods("GET")
	r.HandleFunc("/api/iam/users", api.CreateIAMUser).Methods("POST")
	r.HandleFunc("/api/iam/users/{username}", api.DeleteIAMUser).Methods("DELETE")
	r.HandleFunc("/api/iam/users/{username}/password", api.SetUserPassword).Methods("POST")
	r.HandleFunc("/api/iam/users/{username}/password", api.UpdateUserPassword).Methods("PUT")
	r.HandleFunc("/api/iam/users/{username}/access-keys", api.CreateAccessKey).Methods("POST")
	r.HandleFunc("/api/iam/users/{username}/access-keys", api.ListAccessKeys).Methods("GET")
	r.HandleFunc("/api/iam/users/{username}/groups", api.ListUserGroups).Methods("GET")

	// IAM Groups
	r.HandleFunc("/api/iam/groups", api.ListIAMGroups).Methods("GET")
	r.HandleFunc("/api/iam/groups", api.CreateIAMGroup).Methods("POST")
	r.HandleFunc("/api/iam/groups/{groupname}", api.DeleteIAMGroup).Methods("DELETE")
	r.HandleFunc("/api/iam/groups/{groupname}/users", api.ListUsersInGroup).Methods("GET")
	r.HandleFunc("/api/iam/groups/{groupname}/users", api.AddUserToGroup).Methods("POST")
	r.HandleFunc("/api/iam/groups/{groupname}/users/{username}", api.RemoveUserFromGroup).Methods("DELETE")

	// S3 Buckets
	r.HandleFunc("/api/s3/buckets", api.ListS3Buckets).Methods("GET")
	r.HandleFunc("/api/s3/buckets", api.CreateS3Bucket).Methods("POST")
	r.HandleFunc("/api/s3/buckets/{bucketname}", api.DeleteS3Bucket).Methods("DELETE")
	r.HandleFunc("/api/s3/buckets/{bucketname}/objects", api.ListS3Objects).Methods("GET")
	r.HandleFunc("/api/s3/buckets/{bucketname}/versioning", api.GetBucketVersioning).Methods("GET")
	r.HandleFunc("/api/s3/buckets/{bucketname}/versioning", api.SetBucketVersioning).Methods("PUT")
	r.HandleFunc("/api/s3/buckets/{bucketname}/mfa-delete", api.GetBucketMFADelete).Methods("GET")
	r.HandleFunc("/api/s3/buckets/{bucketname}/mfa-delete", api.UpdateBucketMFADelete).Methods("PUT")

	// CloudWatch
	r.HandleFunc("/api/cloudwatch/logs/{loggroup}", api.GetCloudWatchLogs).Methods("GET")
	r.HandleFunc("/api/cloudwatch/lambda/{function}/logs", api.StreamLambdaLogs).Methods("GET")

	// Settings
	r.HandleFunc("/api/settings/mfa", api.GetMFADevice).Methods("GET")
	r.HandleFunc("/api/settings/mfa", api.SaveMFADevice).Methods("POST")

	// Health
	r.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
	}).Methods("GET")

	log.Println("Server running on :8080")
	log.Fatal(http.ListenAndServe(":8080", corsMiddleware(r)))
}
