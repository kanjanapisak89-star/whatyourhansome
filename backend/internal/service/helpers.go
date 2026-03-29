package service

import (
	"time"

	loftv1 "github.com/medlab/loft/backend/gen/proto/loft/v1"
)

// Helper functions for proto conversions

func unix(t time.Time) int64 {
	if t.IsZero() {
		return 0
	}
	return t.Unix()
}

func protoPublishStatus(s string) loftv1.PublishStatus {
	switch s {
	case "draft":
		return loftv1.PublishStatus_PUBLISH_STATUS_DRAFT
	case "published":
		return loftv1.PublishStatus_PUBLISH_STATUS_PUBLISHED
	case "archived":
		return loftv1.PublishStatus_PUBLISH_STATUS_ARCHIVED
	default:
		return loftv1.PublishStatus_PUBLISH_STATUS_UNSPECIFIED
	}
}

func userPublic(id, name string, headline, avatar *string) *loftv1.UserPublic {
	u := &loftv1.UserPublic{
		Id:          id,
		DisplayName: name,
	}
	if avatar != nil {
		u.AvatarUrl = *avatar
	}
	return u
}

func protoUserRole(role string) loftv1.UserRole {
	switch role {
	case "guest":
		return loftv1.UserRole_USER_ROLE_GUEST
	case "member":
		return loftv1.UserRole_USER_ROLE_MEMBER
	case "admin":
		return loftv1.UserRole_USER_ROLE_ADMIN
	case "owner":
		return loftv1.UserRole_USER_ROLE_OWNER
	default:
		return loftv1.UserRole_USER_ROLE_UNSPECIFIED
	}
}

func protoUserStatus(status string) loftv1.UserStatus {
	switch status {
	case "active":
		return loftv1.UserStatus_USER_STATUS_ACTIVE
	case "blocked":
		return loftv1.UserStatus_USER_STATUS_BLOCKED
	case "deleted":
		return loftv1.UserStatus_USER_STATUS_DELETED
	default:
		return loftv1.UserStatus_USER_STATUS_UNSPECIFIED
	}
}

func protoQuestionStatus(status string) loftv1.QuestionStatus {
	switch status {
	case "pending":
		return loftv1.QuestionStatus_QUESTION_STATUS_PENDING
	case "answered":
		return loftv1.QuestionStatus_QUESTION_STATUS_ANSWERED
	case "archived":
		return loftv1.QuestionStatus_QUESTION_STATUS_ARCHIVED
	default:
		return loftv1.QuestionStatus_QUESTION_STATUS_UNSPECIFIED
	}
}
