package dao

type Doctor struct {
	ID        int        `json:"id"`
	FirstName string     `json:"first_name"`
	LastName  string     `json:"last_name"`
	Gender    string     `json:"gender"`
	Phone     string     `json:"phone"`
	Specialty string     `json:"specialty"`
	Schedule  []Schedule `json:"schedule"`
}
