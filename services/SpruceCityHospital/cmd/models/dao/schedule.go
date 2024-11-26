package dao

type Schedule struct {
	Day       string `xml:"day"`
	StartTime Time   `xml:"start_time"`
	EndTime   Time   `xml:"end_time"`
}
