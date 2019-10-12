package google

import (
	"context"
	"log"
	"time"

	"github.com/sinfo/deck2/src/auth"
	"github.com/sinfo/deck2/src/config"
	"github.com/sinfo/deck2/src/models"
	"github.com/sinfo/deck2/src/mongodb"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"golang.org/x/oauth2"
	"google.golang.org/api/calendar/v3"
	"google.golang.org/api/option"
)

func CreateCalendarEvent(meeting *models.Meeting, tokenID primitive.ObjectID) error {
	if !config.Production {
		log.Println("Running in dev: Skipped Google Calendar Event creation")
		return nil
	}

	ctx := context.Background()

	token, err := mongodb.Tokens.GetToken(tokenID)
	if err != nil {
		return err
	}

	newToken := new(oauth2.Token)
	newToken.Expiry = token.Expiry
	newToken.RefreshToken = token.Refresh
	newToken.AccessToken = token.Access

	client := auth.OauthConfig.Client(ctx, newToken)

	calendarService, err := calendar.NewService(ctx, option.WithHTTPClient(client))
	if err != nil {
		return err
	}

	calendarList, err := calendarService.CalendarList.List().Do()
	if err != nil {
		return err
	}

	var calendarID string

	for _, s := range calendarList.Items {
		if s.Summary == config.SinfoCalendarName {
			calendarID = s.Id
		}
	}

	newEvent := &calendar.Event{
		AnyoneCanAddSelf: true,
		Id:               meeting.ID.Hex(),
		Location:         meeting.Place,
		Summary:          "Event meeting",
		Start:            &calendar.EventDateTime{DateTime: meeting.Begin.Format(time.RFC3339)},
		End:              &calendar.EventDateTime{DateTime: meeting.End.Format(time.RFC3339)},
	}

	createdEvent, err := calendarService.Events.Insert(calendarID, newEvent).Do()
	if err != nil {
		return err
	}

	log.Printf("Created event %s starting at %s", createdEvent.Summary, createdEvent.Start)

	return nil
}

func DeleteCalendarEvent(meetingID, tokenID primitive.ObjectID) error {
	if !config.Production {
		log.Println("Running in dev: Skipped Google Calendar Event deletion")
		return nil
	}

	ctx := context.Background()

	token, err := mongodb.Tokens.GetToken(tokenID)
	if err != nil {
		return err
	}

	newToken := new(oauth2.Token)
	newToken.Expiry = token.Expiry
	newToken.RefreshToken = token.Refresh
	newToken.AccessToken = token.Access

	client := auth.OauthConfig.Client(ctx, newToken)

	calendarService, err := calendar.NewService(ctx, option.WithHTTPClient(client))
	if err != nil {
		return err
	}

	calendarList, err := calendarService.CalendarList.List().Do()
	if err != nil {
		return err
	}

	var calendarID string

	for _, s := range calendarList.Items {
		if s.Summary == config.SinfoCalendarName {
			calendarID = s.Id
		}
	}

	deletedEvent, err := calendarService.Events.Get(calendarID, meetingID.Hex()).Do()
	if err != nil {
		return err
	}

	err = calendarService.Events.Delete(calendarID, meetingID.Hex()).Do()
	if err != nil {
		return err
	}

	log.Printf("Deleted event %s", deletedEvent.Summary)

	return nil
}

func UpdateCalendarEvent(data mongodb.UpdateMeetingData, meetingID, tokenID primitive.ObjectID) error {
	if !config.Production {
		log.Println("Running in dev: Skipped Google Calendar Event deletion")
		return nil
	}

	ctx := context.Background()

	token, err := mongodb.Tokens.GetToken(tokenID)
	if err != nil {
		return err
	}

	newToken := new(oauth2.Token)
	newToken.Expiry = token.Expiry
	newToken.RefreshToken = token.Refresh
	newToken.AccessToken = token.Access

	client := auth.OauthConfig.Client(ctx, newToken)

	calendarService, err := calendar.NewService(ctx, option.WithHTTPClient(client))
	if err != nil {
		return err
	}

	calendarList, err := calendarService.CalendarList.List().Do()
	if err != nil {
		return err
	}

	var calendarID string

	for _, s := range calendarList.Items {
		if s.Summary == config.SinfoCalendarName {
			calendarID = s.Id
		}
	}

	updatedEvent, err := calendarService.Events.Get(calendarID, meetingID.Hex()).Do()
	if err != nil {
		return err
	}

	updatedEvent.Start = &calendar.EventDateTime{DateTime: data.Begin.Format(time.RFC3339)}
	updatedEvent.End = &calendar.EventDateTime{DateTime: data.End.Format(time.RFC3339)}
	updatedEvent.Location = data.Place

	event, err := calendarService.Events.Update(calendarID, meetingID.Hex(), updatedEvent).Do()
	if err != nil {
		return err
	}

	log.Printf("Updated event %s\n", event.Id)

	return nil
}
