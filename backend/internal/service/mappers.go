package service

import (
	"time"

	"github.com/google/uuid"
	loftv1 "github.com/medlab/loft/backend/gen/proto/loft/v1"
)

func userPublic(id uuid.UUID, name string, headline, avatar *string) *loftv1.UserPublic {
	p := &loftv1.UserPublic{Id: id.String(), DisplayName: name}
	if headline != nil {
		p.Headline = *headline
	}
	if avatar != nil {
		p.AvatarUrl = *avatar
	}
	return p
}

func protoPublishStatus(db string) loftv1.PublishStatus {
	switch db {
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

func protoBoardThreadStatus(db string) loftv1.BoardThreadStatus {
	switch db {
	case "open":
		return loftv1.BoardThreadStatus_BOARD_THREAD_STATUS_OPEN
	case "answered":
		return loftv1.BoardThreadStatus_BOARD_THREAD_STATUS_ANSWERED
	case "locked":
		return loftv1.BoardThreadStatus_BOARD_THREAD_STATUS_LOCKED
	case "archived":
		return loftv1.BoardThreadStatus_BOARD_THREAD_STATUS_ARCHIVED
	default:
		return loftv1.BoardThreadStatus_BOARD_THREAD_STATUS_UNSPECIFIED
	}
}

func unix(t time.Time) int64 {
	return t.Unix()
}
