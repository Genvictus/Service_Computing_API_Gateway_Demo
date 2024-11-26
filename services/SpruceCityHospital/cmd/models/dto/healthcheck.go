package dto

import "encoding/xml"

type HealthCheckResponse struct {
	XMLName xml.Name `xml:"healthcheck"`
	Status  string   `xml:"status"`
}
