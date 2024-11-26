package main

type Schedule struct {
	Day       string `json:"day"`
	StartTime string `json:"start_time"`
	EndTime   string `json:"end_time"`
}

type Doctor struct {
	ID        int        `json:"id"`
	FirstName string     `json:"first_name"`
	LastName  string     `json:"last_name"`
	Gender    string     `json:"gender"`
	Phone     string     `json:"phone"`
	Specialty string     `json:"specialty"`
	Schedule  []Schedule `json:"schedule"`
}
