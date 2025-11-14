package api

import (
	"encoding/json"
	"net/http"

	"github.com/DragonEmperor9480/aws_cli_manager/models/s3"
	"github.com/gorilla/mux"
)

// ListS3Buckets returns all S3 buckets
func ListS3Buckets(w http.ResponseWriter, r *http.Request) {
	output := s3.ListS3BucketsModel()
	respondJSON(w, http.StatusOK, map[string]string{"buckets": output})
}

// CreateS3Bucket creates a new S3 bucket
func CreateS3Bucket(w http.ResponseWriter, r *http.Request) {
	var req struct {
		BucketName string `json:"bucketname"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	if req.BucketName == "" {
		respondError(w, http.StatusBadRequest, "bucketname is required")
		return
	}

	s3.CreateS3BucketModel(req.BucketName)
	respondJSON(w, http.StatusOK, map[string]string{"message": "Bucket created", "bucketname": req.BucketName})
}

// DeleteS3Bucket deletes an S3 bucket
func DeleteS3Bucket(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	bucketname := vars["bucketname"]

	err := s3.DeleteS3BucketModel(bucketname)
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	respondJSON(w, http.StatusOK, map[string]string{"message": "Bucket deleted", "bucketname": bucketname})
}

// ListS3Objects lists objects in a bucket
func ListS3Objects(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	bucketname := vars["bucketname"]

	s3.S3ListBucketObjects(bucketname)
	respondJSON(w, http.StatusOK, map[string]string{"message": "Objects listed", "bucketname": bucketname})
}

// GetBucketVersioning gets bucket versioning status
func GetBucketVersioning(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	bucketname := vars["bucketname"]

	status, err := s3.GetBucketVersioningStatusModel(bucketname)
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	respondJSON(w, http.StatusOK, map[string]string{"bucketname": bucketname, "status": status})
}

// SetBucketVersioning sets bucket versioning status
func SetBucketVersioning(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	bucketname := vars["bucketname"]

	var req struct {
		Status string `json:"status"` // "Enabled" or "Suspended"
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	err := s3.SetBucketVersioningModel(bucketname, req.Status)
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	respondJSON(w, http.StatusOK, map[string]string{"message": "Versioning updated", "bucketname": bucketname, "status": req.Status})
}

// GetBucketMFADelete gets MFA delete status
func GetBucketMFADelete(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	bucketname := vars["bucketname"]

	status := s3.GetBucketVersioning(bucketname)
	respondJSON(w, http.StatusOK, map[string]string{"bucketname": bucketname, "status": status})
}

// UpdateBucketMFADelete updates MFA delete setting
func UpdateBucketMFADelete(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	bucketname := vars["bucketname"]

	var req struct {
		SecurityARN string `json:"security_arn"`
		MFACode     string `json:"mfa_code"`
		Enable      bool   `json:"enable"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	s3.UpdateBucketMFADelete(bucketname, req.SecurityARN, req.MFACode, req.Enable)
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"message":    "MFA delete updated",
		"bucketname": bucketname,
		"enabled":    req.Enable,
	})
}
