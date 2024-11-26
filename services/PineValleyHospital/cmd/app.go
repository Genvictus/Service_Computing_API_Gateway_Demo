package main

import (
	"PineValleyHospital/cmd/models/dao"
	"PineValleyHospital/cmd/models/dto"
	"log"

	"github.com/gofiber/fiber/v2"
)

func main() {
	app := fiber.New()

	app.Get("/healthcheck", func(c *fiber.Ctx) error {
		log.Println("Health check request received!")
		response := dto.HealthCheckResponse{
			Status: "ok",
		}
		return c.JSON(response)
	})

	app.Get("/appointments", func(c *fiber.Ctx) error {
		log.Println("Available appointments time requested!")

		doctors := []dao.Doctor{
			{
				ID:        1,
				FirstName: "John",
				LastName:  "Doe",
				Gender:    "Male",
				Phone:     "555-1234",
				Specialty: "Cardiology",
				Schedule: []dao.Schedule{
					{Day: "Monday", StartTime: "09:00 AM", EndTime: "05:00 PM"},
					{Day: "Wednesday", StartTime: "09:00 AM", EndTime: "01:00 PM"},
					{Day: "Friday", StartTime: "02:00 PM", EndTime: "06:00 PM"},
				},
			},
			{
				ID:        2,
				FirstName: "Jane",
				LastName:  "Smith",
				Gender:    "Female",
				Phone:     "555-5678",
				Specialty: "Neurology",
				Schedule: []dao.Schedule{
					{Day: "Tuesday", StartTime: "10:00 AM", EndTime: "04:00 PM"},
					{Day: "Thursday", StartTime: "11:00 AM", EndTime: "03:00 PM"},
				},
			},
			{
				ID:        3,
				FirstName: "Alice",
				LastName:  "Johnson",
				Gender:    "Female",
				Phone:     "555-9876",
				Specialty: "Dermatology",
				Schedule: []dao.Schedule{
					{Day: "Monday", StartTime: "08:30 AM", EndTime: "12:30 PM"},
					{Day: "Wednesday", StartTime: "01:00 PM", EndTime: "05:00 PM"},
				},
			},
			{
				ID:        4,
				FirstName: "Bob",
				LastName:  "Williams",
				Gender:    "Male",
				Phone:     "555-1122",
				Specialty: "Orthopedics",
				Schedule: []dao.Schedule{
					{Day: "Monday", StartTime: "10:00 AM", EndTime: "06:00 PM"},
					{Day: "Thursday", StartTime: "09:00 AM", EndTime: "03:00 PM"},
				},
			},
		}

		return c.JSON(doctors)
	})

	app.Listen(":6969")
}
