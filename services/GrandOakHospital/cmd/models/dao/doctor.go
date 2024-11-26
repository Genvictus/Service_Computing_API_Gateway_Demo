package dao

type Doctor struct {
	ID        int        `json:"id"`
	FullName  string     `json:"full_name"`
	Gender    string     `json:"gender"`
	Phone     string     `json:"phone"`
	Specialty string     `json:"specialty"`
	Schedule  []Schedule `json:"schedule"`
}
