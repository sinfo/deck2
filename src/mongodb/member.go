package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"strings"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var (
	MemberAssociated = "Member associated"
)

// MembersType contains database information on Members
type MembersType struct {
	Collection *mongo.Collection
	Context    context.Context
}

// Cached version of the public members for the current event
var currentPublicMembers *[]*models.MemberPublic

func ResetCurrentPublicMembers() {
	currentPublicMembers = nil
}

// GetMemberOptions is a filter for GetMembers
type GetMemberOptions struct {
	Name  *string
	Event *int
}

// CreateMemberData contains all info needed to create a new member
type CreateMemberData struct {
	Name    string `json:"name"`
	Istid   string `json:"istid"`
	SINFOID string `json:"sinfoid"`
}

// UpdateMemberData contains all info needed to update a member
type UpdateMemberData struct {
	Name  string `json:"name"`
	Istid string `json:"istid"`
}

// DeleteNotificationData contains info needed to delete a member's notification
type DeleteNotificationData struct {
	Notification primitive.ObjectID `json:"notification"`
}

// PublicMemberData contains public information about a member
type PublicMemberData struct {
	ID    primitive.ObjectID `json:"id"`
	Name  string             `json:"name"`
	Image string             `json:"img"`
}

// ParseBody fills the CreateTeamData from a body
func (cmd *CreateMemberData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(cmd); err != nil {
		return err
	}

	if len(cmd.Name) == 0 {
		return errors.New("invalid name")
	}

	if len(cmd.Istid) < 3 || cmd.Istid[:3] != "ist" {
		return errors.New("invalid name")
	}

	if len(cmd.SINFOID) == 0 {
		return errors.New("invalid sinfo ID")
	}

	return nil
}

// ParseBody fills the UpdateMemberData from a body
func (umd *UpdateMemberData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(umd); err != nil {
		return err
	}

	if len(umd.Name) == 0 {
		return errors.New("invalid name")
	}

	if len(umd.Istid) < 3 || umd.Istid[:3] != "ist" {
		return errors.New("invalid name")
	}

	return nil
}

func filterDuplicatesMembers(orig []*models.Member) (res []*models.Member) {
	res = make([]*models.Member, 0)

	for _, s := range orig {
		dup := false
		for _, t := range res {
			if t.ID == s.ID {
				dup = true
				break
			}
		}
		if !dup {
			res = append(res, s)
		}
	}

	return res
}

func convertToPublicMembers(orig []*models.Member) (res []*models.MemberPublic) {

	var public = make([]*models.MemberPublic, 0)

	for _, s := range orig {
		public = append(public, &models.MemberPublic{
			Name:  s.Name,
			Image: s.Image,
		})
	}

	return public
}

// GetMember finds a member with specified id.
func (m *MembersType) GetMemberBySinfoID(sinfoid string) (*models.Member, error) {

	var member models.Member

	if err := m.Collection.FindOne(m.Context, bson.M{"sinfoid": sinfoid}).Decode(&member); err != nil {
		return nil, err
	}

	return &member, nil
}

// GetMember finds a member with specified id.
func (m *MembersType) GetMember(id primitive.ObjectID) (*models.Member, error) {

	var member models.Member

	if err := m.Collection.FindOne(m.Context, bson.M{"_id": id}).Decode(&member); err != nil {
		return nil, err
	}

	return &member, nil
}

// GetMembers retrieves all members if no name is given or all members
// with a case insensitive partial match to given name
// or all members in event if event is given
func (m *MembersType) GetMembers(options GetMemberOptions) ([]*models.Member, error) {

	var members []*models.Member
	filter := bson.M{}

	if options.Name != nil {
		filter["name"] = bson.M{
			"$regex":   fmt.Sprintf(".*%s.*", *options.Name),
			"$options": "i",
		}
	}

	if options.Event == nil {

		cur, err := m.Collection.Find(m.Context, filter)
		if err != nil {
			return nil, err
		}

		for cur.Next(m.Context) {

			var x models.Member

			if err := cur.Decode(&x); err != nil {
				return nil, err
			}

			members = append(members, &x)
		}

		if err := cur.Err(); err != nil {
			return nil, err
		}

		cur.Close(m.Context)

	} else {
		event, err := Events.GetEvent(*options.Event)
		if err != nil {
			return nil, err
		}

		for _, s := range event.Teams {
			team, err := Teams.GetTeam(s)
			if err != nil {
				return nil, err
			}

			for _, t := range team.Members {
				var member models.Member

				findQuery := bson.M{"_id": t.Member,}

				if options.Name != nil {
					findQuery["name"] = filter["name"]
				}

				if err := m.Collection.FindOne(m.Context, findQuery).Decode(&member); err != nil {
					continue
				}

				members = append(members, &member)
			}
		}
	}

	return filterDuplicatesMembers(members), nil
}

// GetMemberAuthCredentials finds a member and returns his/her information for auth purposes.
func (m *MembersType) GetMemberAuthCredentials(sinfoID string) (*models.AuthorizationCredentials, error) {

	var member models.Member
	var result models.AuthorizationCredentials

	if err := m.Collection.FindOne(m.Context, bson.M{"sinfoid": sinfoID}).Decode(&member); err != nil {
		return nil, err
	}

	result.ID = member.ID
	result.SINFOID = member.SINFOID

	currentEvent, err := Events.GetCurrentEvent()
	if err != nil {
		return nil, err
	}

	var options = GetTeamsOptions{Event: &currentEvent.ID, Member: &member.ID}
	teams, err := Teams.GetTeams(options)
	if err != nil {
		return nil, err
	}

	var level = -1
	var role models.TeamRole
	for _, team := range teams {
		member, err := team.GetMember(member.ID)

		if err != nil {
			continue
		}

		l := member.Role.AccessLevel()

		if l == -1 {
			continue
		}

		if level == -1 || level > l {
			level = l
			role = member.Role
		}
	}

	if level == -1 {
		return nil, errors.New("member without team")
	}

	result.Role = role

	return &result, nil
}

// CreateMember creates a new member
func (m *MembersType) CreateMember(data CreateMemberData) (*models.Member, error) {

	createdContact, err := Contacts.Collection.InsertOne(Contacts.Context, bson.M{
		"phones": []models.ContactPhone{},
		"socials": bson.M{
			"facebook": "",
			"skype":    "",
			"github":   "",
			"twitter":  "",
			"linkedin": "",
		},
		"mails": []models.ContactMail{},
	})

	if err != nil {
		return nil, err
	}

	insertData := bson.M{
		"name":    data.Name,
		"istid":   data.Istid,
		"sinfoid": data.SINFOID,
		"contact": createdContact.InsertedID.(primitive.ObjectID),
	}

	insertResult, err := m.Collection.InsertOne(m.Context, insertData)
	if err != nil {
		return nil, err
	}

	newMember, err := m.GetMember(insertResult.InsertedID.(primitive.ObjectID))
	if err != nil {
		return nil, err
	}

	ResetCurrentPublicMembers()

	return newMember, nil
}

// UpdateImage updates a member's image
func (m *MembersType) UpdateImage(memberID primitive.ObjectID, url string) (*models.Member, error) {

	var member models.Member

	var updateQuery = bson.M{
		"$set": bson.M{
			"img": url,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := m.Collection.FindOneAndUpdate(m.Context, bson.M{"_id": memberID}, updateQuery, optionsQuery).Decode(&member); err != nil {
		return nil, err
	}

	ResetCurrentPublicMembers()

	return &member, nil
}

// UpdateMember updates a member's name, image and istid
func (m *MembersType) UpdateMember(id primitive.ObjectID, data UpdateMemberData) (*models.Member, error) {
	var member models.Member

	var updateQuery = bson.M{
		"$set": bson.M{
			"name":  data.Name,
			"istid": data.Istid,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := m.Collection.FindOneAndUpdate(m.Context, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&member); err != nil {
		return nil, err
	}

	ResetCurrentPublicMembers()

	return &member, nil
}

// AddNotification adds notification.
func (m *MembersType) AddNotification(id primitive.ObjectID, notificationID primitive.ObjectID) (*models.Member, error) {

	var member models.Member

	var updateQuery = bson.M{
		"$addToSet": bson.M{
			"notifications": notificationID,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := m.Collection.FindOneAndUpdate(m.Context, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&member); err != nil {
		return nil, err
	}

	return &member, nil
}

// GetMembersPublic retrieves all members if no name is given or all members
// with a case insensitive partial match to given name
// or all members in event if event is given
func (m *MembersType) GetMembersPublic(options GetMemberOptions) ([]*models.MemberPublic, error) {

	var members []*models.Member

	if options.Event != nil {
		event, err := Events.GetEvent(*options.Event)
		if err != nil {
			return nil, err
		}

		for _, s := range event.Teams {
			team, err := Teams.GetTeam(s)

			if err != nil {
				return nil, err
			}

			for _, t := range team.Members {
				member, err := m.GetMember(t.Member)

				if err != nil {
					return nil, err
				}

				members = append(members, member)
			}
		}

	} else if currentPublicMembers != nil {

		var filtered = make([]*models.MemberPublic, 0)

		if options.Name != nil {
			for _, m := range *currentPublicMembers {
				if strings.Contains(strings.ToLower(m.Name), strings.ToLower(*options.Name)) {
					filtered = append(filtered, m)
				}
			}
		} else {
			filtered = *currentPublicMembers
		}

		// return cached and filtered
		return filtered, nil

	} else {

		cur, err := m.Collection.Find(m.Context, bson.M{})
		if err != nil {
			return nil, err
		}

		for cur.Next(m.Context) {

			var member models.Member

			if err := cur.Decode(&member); err != nil {
				return nil, err
			}

			members = append(members, &member)
		}

		if err := cur.Err(); err != nil {
			return nil, err
		}

		cur.Close(m.Context)
	}

	filtered := filterDuplicatesMembers(members)

	// update cached value
	if currentPublicMembers == nil && options.Event == nil {
		p := convertToPublicMembers(filtered)
		currentPublicMembers = &p
	}

	if options.Name != nil {
		var filteredByName = make([]*models.Member, 0)

		for _, member := range filtered {
			if strings.Contains(strings.ToLower(member.Name), strings.ToLower(*options.Name)) {
				filteredByName = append(filteredByName, member)
			}
		}

		filtered = filteredByName
	}

	public := convertToPublicMembers(filtered)

	return public, nil
}

func (m *MembersType) DeleteMember(id primitive.ObjectID) (*models.Member, error) {

	// Check companies
	var c models.Company
	if err := Companies.Collection.FindOne(Companies.Context, bson.M{"participations.member": id}).Decode(&c); err == nil {
		return nil, errors.New(MemberAssociated)
	}

	// Check meetings
	var meeting models.Meeting
	if err := Meetings.Collection.FindOne(Meetings.Context, bson.M{
		"participants.members": id,
	}).Decode(&meeting); err == nil {
		return nil, errors.New(MemberAssociated)
	}

	// Check notifications
	var n models.Notification
	if err := Notifications.Collection.FindOne(Notifications.Context, bson.M{"member": id}).Decode(&n); err == nil {
		return nil, errors.New(MemberAssociated)
	}

	// Check posts
	var p models.Post
	if err := Posts.Collection.FindOne(Posts.Context, bson.M{"member": id}).Decode(&p); err == nil {
		return nil, errors.New(MemberAssociated)
	}

	// Check speakers
	var s models.Speaker
	if err := Speakers.Collection.FindOne(Speakers.Context, bson.M{"participations.member": id}).Decode(&s); err == nil {
		return nil, errors.New(MemberAssociated)
	}

	// Check teams
	var t models.Team
	if err := Teams.Collection.FindOne(Teams.Context, bson.M{"members.member": id}).Decode(&t); err == nil {
		return nil, errors.New(MemberAssociated)
	}

	member, err := m.GetMember(id)
	if err != nil {
		return nil, err
	}

	deleteResult, err := m.Collection.DeleteOne(m.Context, bson.M{"_id": id})
	if err != nil {
		return nil, err
	}

	if deleteResult.DeletedCount != 1 {
		return nil, fmt.Errorf("should have deleted 1 member, deleted %v", deleteResult.DeletedCount)
	}

	return member, nil
}
