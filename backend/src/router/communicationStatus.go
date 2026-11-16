package router

import (
	"fmt"
	"log"

	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// communicationParticipation identifies a participation containing a thread
// before that thread is deleted and its references are removed.
type communicationParticipation struct {
	entityID primitive.ObjectID
	eventID  int
	speaker  bool
}

func hasCommunication(communications []primitive.ObjectID, threadID primitive.ObjectID) bool {
	for _, id := range communications {
		if id == threadID {
			return true
		}
	}
	return false
}

func findCommunicationParticipations(threadID primitive.ObjectID) ([]communicationParticipation, error) {
	var participations []communicationParticipation

	speaker, err := mongodb.Speakers.FindThread(threadID)
	if err != nil {
		return nil, fmt.Errorf("find speaker communication: %w", err)
	}
	if speaker != nil {
		for _, participation := range speaker.Participations {
			if hasCommunication(participation.Communications, threadID) {
				participations = append(participations, communicationParticipation{
					entityID: speaker.ID, eventID: participation.Event, speaker: true,
				})
			}
		}
	}

	company, err := mongodb.Companies.FindThread(threadID)
	if err != nil {
		return nil, fmt.Errorf("find company communication: %w", err)
	}
	if company != nil {
		for _, participation := range company.Participations {
			if hasCommunication(participation.Communications, threadID) {
				participations = append(participations, communicationParticipation{
					entityID: company.ID, eventID: participation.Event,
				})
			}
		}
	}

	return participations, nil
}

func belongsToParticipation(participations []communicationParticipation, entityID primitive.ObjectID, speaker bool) bool {
	for _, participation := range participations {
		if participation.entityID == entityID && participation.speaker == speaker {
			return true
		}
	}
	return false
}

// recalculateDeletedCommunicationStatuses keeps the remaining-message status
// in sync with deletion. Notify() currently targets only the current event.
func recalculateDeletedCommunicationStatuses(participations []communicationParticipation, authorID primitive.ObjectID) error {
	if len(participations) == 0 {
		return nil
	}

	currentEvent, eventErr := mongodb.Events.GetCurrentEvent()
	if eventErr != nil {
		log.Printf("Could not resolve event for communication status notifications: %v", eventErr)
	}

	for _, participation := range participations {
		var newStatus *models.ParticipationStatus
		var err error

		if participation.speaker {
			_, newStatus, err = mongodb.Speakers.AutoUpdateParticipationStatus(participation.entityID, participation.eventID)
		} else {
			_, newStatus, err = mongodb.Companies.AutoUpdateParticipationStatus(participation.entityID, participation.eventID)
		}
		if err != nil {
			return fmt.Errorf("recalculate status for entity %s, event %d: %w", participation.entityID.Hex(), participation.eventID, err)
		}
		if newStatus == nil || eventErr != nil || currentEvent.ID != participation.eventID {
			continue
		}

		notification := mongodb.CreateNotificationData{Kind: models.NotificationKindUpdatedParticipationStatus}
		if participation.speaker {
			notification.Speaker = &participation.entityID
		} else {
			notification.Company = &participation.entityID
		}
		mongodb.Notifications.Notify(authorID, notification)
	}
	return nil
}
