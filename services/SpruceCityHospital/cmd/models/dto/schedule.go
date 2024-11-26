package dto

import (
	"SpruceCityHospital/cmd/models/dao"
	"encoding/xml"
)

type ScheduleResponse struct {
	XMLName xml.Name     `xml:"doctors"`
	Doctors []dao.Doctor `xml:"doctor"`
}
