package api

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/DragonEmperor9480/aws_cli_manager/models/iam/group"
	"github.com/DragonEmperor9480/aws_cli_manager/models/iam/user"
	"github.com/gorilla/mux"
)

// ListIAMUsers returns all IAM users
func ListIAMUsers(w http.ResponseWriter, r *http.Request) {
	output, err := user.FetchIAMUsers()
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	users := parseTabSeparated(output, []string{"username", "user_id", "create_date"})
	respondJSON(w, http.StatusOK, map[string]interface{}{"users": users})
}

// CreateIAMUser creates a new IAM user
func CreateIAMUser(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Username string `json:"username"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	if req.Username == "" {
		respondError(w, http.StatusBadRequest, "username is required")
		return
	}

	user.CreateIAMUser(req.Username)
	respondJSON(w, http.StatusOK, map[string]string{"message": "User created", "username": req.Username})
}

// CheckUserDependencies checks what dependencies a user has before deletion
func CheckUserDependencies(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	username := vars["username"]

	deps, err := user.CheckUserDependencies(username)
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	respondJSON(w, http.StatusOK, deps)
}

// DeleteIAMUser deletes an IAM user (with force flag to remove dependencies)
func DeleteIAMUser(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	username := vars["username"]

	// Check for force parameter
	force := r.URL.Query().Get("force") == "true"

	if !force {
		// Check if user has dependencies
		deps, err := user.CheckUserDependencies(username)
		if err != nil {
			respondError(w, http.StatusInternalServerError, err.Error())
			return
		}

		if deps.HasDependencies() {
			respondError(w, http.StatusBadRequest, "User has dependencies. Use force=true to delete with dependencies.")
			return
		}
	}

	err := user.DeleteIAMUserAPI(username)
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}
	respondJSON(w, http.StatusOK, map[string]string{"message": "User deleted", "username": username})
}

// SetUserPassword sets initial password for a user
func SetUserPassword(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	username := vars["username"]

	var req struct {
		Password string `json:"password"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	user.SetInitialUserPasswordModel(username, req.Password)
	respondJSON(w, http.StatusOK, map[string]string{"message": "Password set", "username": username})
}

// UpdateUserPassword updates user password
func UpdateUserPassword(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	username := vars["username"]

	var req struct {
		Password string `json:"password"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	user.UpdateUserPasswordModel(username, req.Password)
	respondJSON(w, http.StatusOK, map[string]string{"message": "Password updated", "username": username})
}

// CreateAccessKey creates access key for user
func CreateAccessKey(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	username := vars["username"]

	user.CreateAccessKeyForUserModel(username)
	respondJSON(w, http.StatusOK, map[string]string{"message": "Access key created", "username": username})
}

// ListAccessKeys lists access keys for user
func ListAccessKeys(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	username := vars["username"]

	user.ListAccessKeysForUserModel(username)
	respondJSON(w, http.StatusOK, map[string]string{"message": "Access keys listed", "username": username})
}

// ============ IAM GROUPS ============

// ListIAMGroups returns all IAM groups
func ListIAMGroups(w http.ResponseWriter, r *http.Request) {
	output, err := group.FetchIAMGroups()
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	groups := parseTabSeparated(output, []string{"groupname", "group_id", "create_date"})
	respondJSON(w, http.StatusOK, map[string]interface{}{"groups": groups})
}

// CreateIAMGroup creates a new IAM group
func CreateIAMGroup(w http.ResponseWriter, r *http.Request) {
	var req struct {
		GroupName string `json:"groupname"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	if req.GroupName == "" {
		respondError(w, http.StatusBadRequest, "groupname is required")
		return
	}

	group.CreateIAMGroup(req.GroupName)
	respondJSON(w, http.StatusOK, map[string]string{"message": "Group created", "groupname": req.GroupName})
}

// DeleteIAMGroup deletes an IAM group
func DeleteIAMGroup(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	groupname := vars["groupname"]

	group.DeleteGroupModel(groupname)
	respondJSON(w, http.StatusOK, map[string]string{"message": "Group deleted", "groupname": groupname})
}

// AddUserToGroup adds a user to a group
func AddUserToGroup(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	groupname := vars["groupname"]

	var req struct {
		Username string `json:"username"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	group.AddUserToGroupModel(req.Username, groupname)
	respondJSON(w, http.StatusOK, map[string]string{"message": "User added to group", "username": req.Username, "groupname": groupname})
}

// RemoveUserFromGroup removes a user from a group
func RemoveUserFromGroup(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	groupname := vars["groupname"]
	username := vars["username"]

	group.RemoveUserFromGroupModel(username, groupname)
	respondJSON(w, http.StatusOK, map[string]string{"message": "User removed from group", "username": username, "groupname": groupname})
}

// ListUsersInGroup lists all users in a group
func ListUsersInGroup(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	groupname := vars["groupname"]

	group.ListUsersInGroupModel(groupname)
	respondJSON(w, http.StatusOK, map[string]string{"message": "Users listed", "groupname": groupname})
}

// ListUserGroups lists all groups for a user
func ListUserGroups(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	username := vars["username"]

	groups := group.ListUserGroupsModel(username)
	respondJSON(w, http.StatusOK, map[string]interface{}{"username": username, "groups": groups})
}

// ============ HELPER FUNCTIONS ============

func parseTabSeparated(output string, fields []string) []map[string]string {
	result := []map[string]string{}
	lines := strings.Split(strings.TrimSpace(output), "\n")

	for _, line := range lines {
		if line == "" {
			continue
		}
		parts := strings.Split(line, "\t")
		if len(parts) >= len(fields) {
			item := make(map[string]string)
			for i, field := range fields {
				item[field] = parts[i]
			}
			result = append(result, item)
		}
	}

	return result
}

func respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func respondError(w http.ResponseWriter, status int, message string) {
	respondJSON(w, status, map[string]string{"error": message})
}
