package mongodb

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log"
	"strings"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/sinfo/deck2/src/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	//"go.mongodb.org/mongo-driver/mongo/options"
)


// MembersType contains database information on Members
type MembersType struct {
	Collection *mongo.Collection
	Context    context.Context
}

// GetMemberOptions is a filter for GetMembers
type GetMemberOptions struct {
	Name	*string
}

// CreateMemberData contains all info needed to create a new member
type CreateMemberData struct {
	Name	string
	Image	string
	Istid	string
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
// GetMembers retrieves all members if no name is given or all members 
// with a case insensitive partial match to given name
func (m *MembersType) GetMembers(options GetMemberOptions) ([]*models.Member, error) {

	var members []*models.Member

	cur, err := m.Collection.Find(m.Context, bson.M{})
	if err != nil{
		log.Println("error 1")
		return nil, err
	}

	for cur.Next(m.Context) {
		
		var x models.Member

		if err := cur.Decode(&x); err != nil{
			log.Println("error 2")
			return nil, err
		}

		if options.Name == nil{
			members = append(members, &x)
		}else if strings.Contains(strings.ToLower(x.Name),strings.ToLower(*options.Name)){
			members = append(members, &x)
		}
	}

	if err := cur.Err(); err != nil {
		log.Println("error 3")
		return nil, err
	}

	cur.Close(m.Context)

	return members, nil
}

// GetMember finds a member with specified id.
func (m *MembersType) GetMember(id primitive.ObjectID) (*models.Member, error){

	var member models.Member

	if err := m.Collection.FindOne(m.Context, bson.M{"_id": id}).Decode(&member); err != nil{
		return nil, err
	}

	return &member, nil
}

// CreateMember creates a new member
func (m *MembersType) CreateMember (data CreateMemberData) (*models.Member,error){

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

