package dao

type Doctor struct {
	ID        int        `xml:"id"`
	FirstName string     `xml:"first_name"`
	LastName  string     `xml:"last_name"`
	Gender    bool       `xml:"gender"`
	Phone     string     `xml:"phone"`
	Email     string     `xml:"email"`
	Expertise string     `xml:"specialty"`
	Schedule  []Schedule `xml:"schedule"`
}
