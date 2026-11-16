package mongodb

import (
	"context"
	"fmt"

	"github.com/sinfo/deck2/src/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// autoUpdateParticipationStatus applies the same rule to company and speaker
// participations, using a conditional update to protect concurrent changes.
func autoUpdateParticipationStatus(collection *mongo.Collection, entityID primitive.ObjectID, eventID int) (*models.ParticipationStatus, error) {
	if eventID <= 0 {
		return nil, fmt.Errorf("invalid event ID: %d", eventID)
	}

	ctx := context.Background()
	const maxRetries = 5
	for attempt := 0; attempt < maxRetries; attempt++ {
		var document struct {
			Participations []struct {
				Status         models.ParticipationStatus `bson:"status"`
				Communications []primitive.ObjectID       `bson:"communications"`
			} `bson:"participations"`
		}
		filter := bson.M{"_id": entityID, "participations.event": eventID}
		projection := bson.M{"participations": bson.M{"$elemMatch": bson.M{"event": eventID}}}
		if err := collection.FindOne(ctx, filter, options.FindOne().SetProjection(projection)).Decode(&document); err != nil {
			return nil, fmt.Errorf("find participation for event %d: %w", eventID, err)
		}
		if len(document.Participations) == 0 {
			return nil, fmt.Errorf("participation for event %d not found", eventID)
		}

		participation := document.Participations[0]
		if participation.Status != models.Selected && participation.Status != models.Contacted {
			return nil, nil
		}
		threadsByID, err := Threads.GetThreadsByIDs(participation.Communications)
		if err != nil {
			return nil, fmt.Errorf("load participation communications: %w", err)
		}
		var hasOutgoing, hasIncoming bool
		for _, threadID := range participation.Communications {
			thread, exists := threadsByID[threadID]
			if !exists {
				return nil, fmt.Errorf("communication %s is missing", threadID.Hex())
			}
			hasOutgoing = hasOutgoing || thread.Kind == models.ThreadKindTo
			hasIncoming = hasIncoming || thread.Kind == models.ThreadKindFrom
		}
		nextStatus := models.NextCommunicationStatus(participation.Status, hasOutgoing, hasIncoming)
		if nextStatus == participation.Status {
			return nil, nil
		}

		result, err := collection.UpdateOne(ctx, bson.M{
			"_id": entityID,
			"participations": bson.M{"$elemMatch": bson.M{
				"event": eventID, "status": participation.Status,
			}},
		}, bson.M{"$set": bson.M{"participations.$.status": nextStatus}})
		if err != nil {
			return nil, fmt.Errorf("update participation status for event %d: %w", eventID, err)
		}
		if result.MatchedCount == 1 {
			return &nextStatus, nil
		}
	}
	return nil, fmt.Errorf("participation status changed concurrently for event %d after %d retries", eventID, maxRetries)
}
