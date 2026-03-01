package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/bsontype"
)

// ============================================================
// Shared task fields (used by both companies and speakers)
// ============================================================

// TaskLogos tracks logo delivery status.
type TaskLogos struct {
	Received       bool `json:"received" bson:"received"`
	NeedsReviewing bool `json:"needsReviewing" bson:"needsReviewing"`
}

// ============================================================
// Company-specific task types
// ============================================================

// CompanyTaskConfirmation tracks confirmation-related progress for a company.
type CompanyTaskConfirmation struct {
	AskedForInfo bool `json:"askedForInfo" bson:"askedForInfo"`
}

// CompanyTaskContract tracks contract lifecycle.
type CompanyTaskContract struct {
	Sent        bool `json:"sent" bson:"sent"`
	Created     bool `json:"created" bson:"created"`
	Signed      bool `json:"signed" bson:"signed"`
	ReceiptSent bool `json:"receiptSent" bson:"receiptSent"`
	Paid        bool `json:"paid" bson:"paid"`
}

// CompanyTaskSessionTitles tracks session / workshop titles.
type CompanyTaskSessionTitles struct {
	PresentationTitle string `json:"presentationTitle" bson:"presentationTitle"`
	WorkshopTitle     string `json:"workshopTitle" bson:"workshopTitle"`
}

// CompanyTaskCorlief tracks Corlief-related steps.
type CompanyTaskCorlief struct {
	PreNotice bool `json:"preNotice" bson:"preNotice"`
	Scheduled bool `json:"scheduled" bson:"scheduled"`
	Reserved  bool `json:"reserved" bson:"reserved"`
}

// CompanyTaskLogistics tracks logistics info.
type CompanyTaskLogistics struct {
	RequestedInfo bool   `json:"requestedInfo" bson:"requestedInfo"`
	CarStatus     string `json:"carStatus" bson:"carStatus"` // "not_responded", "wants", "not_wants"
	LicensePlate  string `json:"licensePlate" bson:"licensePlate"`
}

// CompanyTasks is the top-level task object embedded in CompanyParticipation.
type CompanyTasks struct {
	Confirmation  CompanyTaskConfirmation  `json:"confirmation" bson:"confirmation"`
	Logos         TaskLogos                `json:"logos" bson:"logos"`
	Contract      CompanyTaskContract      `json:"contract" bson:"contract"`
	SessionTitles CompanyTaskSessionTitles `json:"sessionTitles" bson:"sessionTitles"`
	Corlief       CompanyTaskCorlief       `json:"corlief" bson:"corlief"`
	Logistics     CompanyTaskLogistics     `json:"logistics" bson:"logistics"`
	PO            string                   `json:"po" bson:"po"`
}

// ============================================================
// Speaker-specific task types
// ============================================================

// SpeakerTaskConfirmation tracks confirmation-related progress for a speaker.
type SpeakerTaskConfirmation struct {
	Phone         string `json:"phone" bson:"phone"`
	LinkedIn      string `json:"linkedin" bson:"linkedin"`
	WantsLinkedIn string `json:"wantsLinkedinTag" bson:"wantsLinkedinTag"` // "not_responded", "yes", "no"
	Observations  string `json:"observations" bson:"observations"`
}

// UnmarshalBSON handles legacy bool values stored for WantsLinkedIn.
func (s *SpeakerTaskConfirmation) UnmarshalBSON(data []byte) error {
	var raw bson.Raw
	if err := bson.Unmarshal(data, &raw); err != nil {
		return err
	}

	decodeString := func(key string) string {
		val, err := raw.LookupErr(key)
		if err != nil {
			return ""
		}
		if val.Type == bsontype.String {
			v, _ := val.StringValueOK()
			return v
		}
		return ""
	}

	decodeLinkedIn := func(key string) string {
		val, err := raw.LookupErr(key)
		if err != nil {
			return "not_responded"
		}
		switch val.Type {
		case bsontype.Boolean:
			b, _ := val.BooleanOK()
			return boolToString(b)
		case bsontype.String:
			v, _ := val.StringValueOK()
			return v
		default:
			return "not_responded"
		}
	}

	s.Phone = decodeString("phone")
	s.LinkedIn = decodeString("linkedin")
	s.WantsLinkedIn = decodeLinkedIn("wantsLinkedinTag")
	s.Observations = decodeString("observations")
	return nil
}

// MarshalBSON always writes string values.
func (s SpeakerTaskConfirmation) MarshalBSON() ([]byte, error) {
	return bson.Marshal(bson.D{
		{Key: "phone", Value: s.Phone},
		{Key: "linkedin", Value: s.LinkedIn},
		{Key: "wantsLinkedinTag", Value: s.WantsLinkedIn},
		{Key: "observations", Value: s.Observations},
	})
}

// SpeakerTaskFlightLeg stores one leg (arrival or departure).
type SpeakerTaskFlightLeg struct {
	Airport      string     `json:"airport" bson:"airport"`
	FlightNumber string     `json:"flightNumber" bson:"flightNumber"`
	Date         *time.Time `json:"date,omitempty" bson:"date,omitempty"`
	Time         string     `json:"time" bson:"time"`
}

// SpeakerTaskFlightDetails stores pricing / status / booking info.
type SpeakerTaskFlightDetails struct {
	Price      string `json:"price" bson:"price"`
	Status     string `json:"status" bson:"status"` // "pending", "received", "approved", "bought"
	Link       string `json:"link" bson:"link"`
	BookingRef string `json:"bookingRef" bson:"bookingRef"`
}

// SpeakerTaskFlightRefund stores refund info.
type SpeakerTaskFlightRefund struct {
	Amount     string `json:"amount" bson:"amount"`
	Method     string `json:"method" bson:"method"`
	InfoNeeded string `json:"infoNeeded" bson:"infoNeeded"`
	Status     string `json:"status" bson:"status"` // "not_started", "receipt_requested", "info_requested", "done"
}

// SpeakerTaskFlights stores everything flight-related.
type SpeakerTaskFlights struct {
	NeedsFlights string                   `json:"needsFlights" bson:"needsFlights"` // "not_responded", "yes", "no"
	Requested    bool                     `json:"requested" bson:"requested"`
	Arrival      SpeakerTaskFlightLeg     `json:"arrival" bson:"arrival"`
	Departure    SpeakerTaskFlightLeg     `json:"departure" bson:"departure"`
	Details      SpeakerTaskFlightDetails `json:"details" bson:"details"`
	Refund       SpeakerTaskFlightRefund  `json:"refund" bson:"refund"`
}

// SpeakerTaskCoverage tracks video/photo coverage confirmation.
type SpeakerTaskCoverage struct {
	Video     string `json:"video" bson:"video"`         // "not_responded", "yes", "no"
	Streaming string `json:"streaming" bson:"streaming"` // "not_responded", "yes", "no"
	Photo     string `json:"photo" bson:"photo"`         // "not_responded", "yes", "no"
}

// boolToString converts legacy boolean values to the new string format.
func boolToString(v interface{}) string {
	switch b := v.(type) {
	case bool:
		if b {
			return "yes"
		}
		return "no"
	case string:
		return b
	default:
		return "not_responded"
	}
}

// UnmarshalBSON handles legacy boolean fields being decoded into string fields.
func (c *SpeakerTaskCoverage) UnmarshalBSON(data []byte) error {
	var raw bson.Raw
	if err := bson.Unmarshal(data, &raw); err != nil {
		return err
	}

	decodeField := func(key string) string {
		val, err := raw.LookupErr(key)
		if err != nil {
			return "not_responded"
		}
		switch val.Type {
		case bsontype.Boolean:
			b, _ := val.BooleanOK()
			return boolToString(b)
		case bsontype.String:
			s, _ := val.StringValueOK()
			return s
		default:
			return "not_responded"
		}
	}

	c.Video = decodeField("video")
	c.Streaming = decodeField("streaming")
	c.Photo = decodeField("photo")
	return nil
}

// MarshalBSON always writes string values.
func (c SpeakerTaskCoverage) MarshalBSON() ([]byte, error) {
	return bson.Marshal(bson.D{
		{Key: "video", Value: c.Video},
		{Key: "streaming", Value: c.Streaming},
		{Key: "photo", Value: c.Photo},
	})
}

// SpeakerTaskMaterials tracks talk info and materials delivery.
type SpeakerTaskMaterials struct {
	Requested       bool   `json:"requested" bson:"requested"`
	TalkTitle       string `json:"talkTitle" bson:"talkTitle"`
	TalkDescription string `json:"talkDescription" bson:"talkDescription"`
	Received        bool   `json:"received" bson:"received"`
	TestSchedule    string `json:"testSchedule" bson:"testSchedule"`
	TestDone        bool   `json:"testDone" bson:"testDone"`
}

// SpeakerTaskHotel stores hotel / booking / payment info.
type SpeakerTaskHotel struct {
	NeedsHotel string     `json:"needsHotel" bson:"needsHotel"` // "not_responded", "yes", "no"
	Requested  bool       `json:"requested" bson:"requested"`
	HotelName  string     `json:"hotelName" bson:"hotelName"`
	RoomType   string     `json:"roomType" bson:"roomType"`
	Price      string     `json:"price" bson:"price"`
	CheckIn    *time.Time `json:"checkIn,omitempty" bson:"checkIn,omitempty"`
	CheckOut   *time.Time `json:"checkOut,omitempty" bson:"checkOut,omitempty"`
	NumNights  string     `json:"numNights" bson:"numNights"`
	NumGuests  string     `json:"numGuests" bson:"numGuests"`
	GuestNames string     `json:"guestNames" bson:"guestNames"`
	Invoice    bool       `json:"invoice" bson:"invoice"`
	Paid       bool       `json:"paid" bson:"paid"`
	Notes      string     `json:"notes" bson:"notes"`
}

// SpeakerTasks is the top-level task object embedded in SpeakerParticipation.
type SpeakerTasks struct {
	Confirmation SpeakerTaskConfirmation `json:"confirmation" bson:"confirmation"`
	Logos        TaskLogos               `json:"logos" bson:"logos"`
	AskedForInfo bool                    `json:"askedForInfo" bson:"askedForInfo"`
	Flights      SpeakerTaskFlights      `json:"flights" bson:"flights"`
	Coverage     SpeakerTaskCoverage     `json:"coverage" bson:"coverage"`
	Materials    SpeakerTaskMaterials    `json:"materials" bson:"materials"`
	Hotel        SpeakerTaskHotel        `json:"hotel" bson:"hotel"`
}
