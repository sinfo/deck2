package auth

import "github.com/sinfo/deck2/src/models"

func CheckAccessLevel(required models.TeamRole, credentials models.AuthorizationCredentials) bool {

	requiredLevel := required.AccessLevel()

	// this should not happen
	if requiredLevel < 0 {
		return false
	}

	level := credentials.Role.AccessLevel()

	if level < 0 || level > requiredLevel {
		return false
	}

	return true
}
