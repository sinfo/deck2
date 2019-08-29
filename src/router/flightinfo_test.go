package router

import (
	"time"

	"github.com/sinfo/deck2/src/models"
)

var (
	TimeFuture = TimeAfter.Add(time.Hour * 10)
	FlightInfo = models.FlightInfo{
		Inbound:  TimeFuture,
		Outbound: TimeAfter,
		From:     "Tashkent International Airport",
		To:       "Humberto Delgado Airport",
		Link:     "https://flightCompany.com/flight/1234567",
		Bought:   true,
		Cost:     23300,
		Notes:    "speaker's mom",
	}
)
