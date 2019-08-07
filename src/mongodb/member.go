package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"strings"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)


// MembersType contains database information on Members
type MembersType struct {
	Collection *mongo.Collection
	Context    context.Context
}

// GetMemberOptions is a filter for GetMembers
type GetMemberOptions struct {
	Name	*string
	Event	*int
}

// CreateMemberData contains all info needed to create a new member
type CreateMemberData struct {
	Name	string	`json:"name"`
	Image	string	`json:"img"`
	Istid	string	`json:"istid"`
}

// UpdateMemberContactData contains info needed to update a member's contact
type UpdateMemberContactData struct {
	Contact	primitive.ObjectID `json:"contact"`
}

// DeleteMemberNotificationData contains info needed to delete a member's notification
type DeleteMemberNotificationData struct {
	Notification primitive.ObjectID `json:"notification"`
}

// PublicMemberData contains public information about a member
type PublicMemberData struct {
	ID		primitive.ObjectID	`json:"id"`
	Name	string				`json:"name"`
	Image	string				`json:"img"`
}

// ParseBody fills the CreateTeamData from a body
func (cmd *CreateMemberData) ParseBody(body io.Reader) error {

	if err := json.NewDecoder(body).Decode(cmd); err != nil {
		return err
	}

	if len(cmd.Name) == 0 {
		return errors.New("invalid name")
	}
	if len(cmd.Image) == 0 {
		return errors.New("invalid image")
	}
	if len(cmd.Istid) < 3 ||cmd.Istid[:3] != "ist" {
		return errors.New("invalid name")
	}

	return nil
}

func filterDuplicates(orig []*models.Member) (res []*models.Member){
	for _, s := range orig{
		dup := false
		for _, t := range res{
			if t.ID == s.ID{
				dup = true
			}
		}
		if !dup{
			res = append(res, s)
		}
	}
	return
}

func filterDuplicatesPublic(orig []*models.MemberPublic) (res []*models.MemberPublic){
	for _, s := range orig{
		dup := false
		for _, t := range res{
			if t.ID == s.ID{
				dup = true
			}
		}
		if !dup{
			res = append(res, s)
		}
	}
	return
}

// GetMember finds a member with specified id.
func (m *MembersType) GetMember(id primitive.ObjectID) (*models.Member, error){

	var member models.Member

	if err := m.Collection.FindOne(m.Context, bson.M{"_id": id}).Decode(&member); err != nil{
		return nil, err
	}

	return &member, nil
}

// GetMembers retrieves all members if no name is given or all members 
// with a case insensitive partial match to given name
// or all members in event if event is given
func (m *MembersType) GetMembers(options GetMemberOptions) ([]*models.Member, error) {

	var members []*models.Member

	if options.Event == nil{

		cur, err := m.Collection.Find(m.Context, bson.M{})
		if err != nil{
			return nil, err
		}

		for cur.Next(m.Context) {
			
			var x models.Member

			if err := cur.Decode(&x); err != nil{
				return nil, err
			}

			if options.Name == nil{
				members = append(members, &x)
			}else if strings.Contains(strings.ToLower(x.Name),strings.ToLower(*options.Name)){
				members = append(members, &x)
			}
		}

		if err := cur.Err(); err != nil {

			return nil, err
		}

		cur.Close(m.Context)

	}else{
		event, err := Events.GetEvent(*options.Event)
		if err != nil {
			return nil, err
		}

		for _, s := range event.Teams{
			team, err := Teams.GetTeam(s)
			if err != nil{
				return nil, err
			}
			for _, t := range team.Members{
				member, err := m.GetMember(t.Member)
				if err != nil {
					return nil, err
				}
				if options.Name == nil{
					members = append(members, member)
				}else if strings.Contains(strings.ToLower(member.Name),strings.ToLower(*options.Name)){
					members = append(members, member)
				}
			}
		}
	}
	return filterDuplicates(members), nil
}

// CreateMember creates a new member
func (m *MembersType) CreateMember(data CreateMemberData) (*models.Member,error){

	insertData := bson.M{}

	insertData["name"] = data.Name
	insertData["img"] = data.Image
	insertData["istid"] = data.Istid

	insertResult, err := m.Collection.InsertOne(m.Context, insertData)
	if err != nil{
		return nil, err
	}

	newMember, err := m.GetMember(insertResult.InsertedID.(primitive.ObjectID))
	if err != nil {
		return nil, err
	}

	return newMember,nil
}

// UpdateMemberContact updates a member's contact 
func (m *MembersType) UpdateMemberContact(id primitive.ObjectID, data UpdateMemberContactData) (*models.Member, error){

	// TODO: Verify that contact exists

	var member models.Member

	var updateQuery = bson.M{
		"$set": bson.M{
			"contact":  data.Contact,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := m.Collection.FindOneAndUpdate(m.Context, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&member); err != nil{
		return nil, err
	}

	return &member, nil
}

// UpdateMember updates a member's name, image and istid
func (m *MembersType) UpdateMember(id primitive.ObjectID, data CreateMemberData) (*models.Member, error){
	var member models.Member

	var updateQuery = bson.M{
		"$set": bson.M{
			"name":		data.Name,
			"img":		data.Image,
			"istid":	data.Istid,		
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := m.Collection.FindOneAndUpdate(m.Context, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(&member); err != nil{
		return nil, err
	}

	return &member, nil
}

// UpdateMemberNotification adds notifications.
func (m *MembersType) UpdateMemberNotification(id primitive.ObjectID, notifs []primitive.ObjectID) (*models.Member, error){

	member, err := m.GetMember(id)
	if err != nil{
		return nil, err
	}

	notifications := append(member.Notifications, notifs...)

	var updateQuery = bson.M{
		"$set": bson.M{
			"notifications" : notifications,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)

	if err := m.Collection.FindOneAndUpdate(m.Context, bson.M{"_id": id}, updateQuery, optionsQuery).Decode(member); err != nil{
		return nil, err
	}

	return member, nil
}

// DeleteMemberNotification deletes a notification from a member.
func (m *MembersType) DeleteMemberNotification(memberID primitive.ObjectID, notif DeleteMemberNotificationData) (*models.Member, error){
	member, err := m.GetMember(memberID)
	if err != nil{
		return nil, err
	}

	var notifications []primitive.ObjectID
	var found = false
	for i, s := range member.Notifications{
		if s == notif.Notification{
			notifications = append(member.Notifications[:i], member.Notifications[i+1:]...)
			found = true
		}
	} 

	if !found {
		return nil, errors.New("Notification not found")
	}

	var updateQuery = bson.M{
		"$set": bson.M{
			"notifications": notifications,
		},
	}

	var optionsQuery = options.FindOneAndUpdate()
	optionsQuery.SetReturnDocument(options.After)
	
	var result models.Member

	if err := m.Collection.FindOneAndUpdate(m.Context, bson.M{"_id": memberID}, updateQuery, optionsQuery).Decode(&result); err != nil{
		return nil, err
	}

	return &result, nil
}

// GetMemberPublic finds a member with specified id.
func (m *MembersType) GetMemberPublic(id primitive.ObjectID) (*models.MemberPublic, error){

	var member models.Member

	if err := m.Collection.FindOne(m.Context, bson.M{"_id": id}).Decode(&member); err != nil{
		return nil, err
	}

	return &models.MemberPublic{
		ID: member.ID,
		Name: member.Name,
		Image: member.Image,
	}, nil
}

// GetMembersPublic retrieves all members if no name is given or all members 
// with a case insensitive partial match to given name
// or all members in event if event is given
func (m *MembersType) GetMembersPublic(options GetMemberOptions) ([]*models.MemberPublic, error) {

	var members []*models.MemberPublic

	if options.Event == nil{

		cur, err := m.Collection.Find(m.Context, bson.M{})
		if err != nil{
			return nil, err
		}

		for cur.Next(m.Context) {
			
			var member models.Member

			if err := cur.Decode(&member); err != nil{
				return nil, err
			}

			if options.Name == nil{
				members = append(members, &models.MemberPublic{
					ID: member.ID,
					Name: member.Name,
					Image: member.Image,
				})
			}else if strings.Contains(strings.ToLower(member.Name),strings.ToLower(*options.Name)){
				members = append(members, &models.MemberPublic{
					ID: member.ID,
					Name: member.Name,
					Image: member.Image,
				})
			}
		}

		if err := cur.Err(); err != nil {

			return nil, err
		}

		cur.Close(m.Context)

	}else{
		event, err := Events.GetEvent(*options.Event)
		if err != nil {
			return nil, err
		}

		for _, s := range event.Teams{
			team, err := Teams.GetTeam(s)
			if err != nil{
				return nil, err
			}
			for _, t := range team.Members{
				member, err := m.GetMember(t.Member)
				if err != nil {
					return nil, err
				}
				if options.Name == nil{
					members = append(members, &models.MemberPublic{
						ID: member.ID,
						Name: member.Name,
						Image: member.Image,
					})
				}else if strings.Contains(strings.ToLower(member.Name),strings.ToLower(*options.Name)){
					members = append(members, &models.MemberPublic{
						ID: member.ID,
						Name: member.Name,
						Image: member.Image,
					})
				}
			}
		}
	}
	return filterDuplicatesPublic(members), nil
}