package main

import (
	"SpruceCityHospital/cmd/models/dao"
	"SpruceCityHospital/cmd/models/dto"
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
		return c.XML(response)
	})

	app.Get("/schedules", func(c *fiber.Ctx) error {
		log.Println("Available schedules time requested!")

		doctors := []dao.Doctor{
			{
				ID:        1,
				FirstName: "Luca",
				LastName:  "Rossi",
				Gender:    false,
				Phone:     "123-456-7890",
				Email:     "luca.rossi@italy.com",
				Expertise: "Cardiology",
				Schedule: []dao.Schedule{
					{
						Day:       "Monday",
						StartTime: dao.Time{Hour: 9, Minute: 0},
						EndTime:   dao.Time{Hour: 17, Minute: 0},
					},
				},
			},
			{
				ID:        2,
				FirstName: "Sofia",
				LastName:  "García",
				Gender:    true,
				Phone:     "987-654-3210",
				Email:     "sofia.garcia@spain.com",
				Expertise: "Neurology",
				Schedule: []dao.Schedule{
					{
						Day:       "Tuesday",
						StartTime: dao.Time{Hour: 10, Minute: 30},
						EndTime:   dao.Time{Hour: 16, Minute: 30},
					},
				},
			},
			{
				ID:        3,
				FirstName: "Yuki",
				LastName:  "Takahashi",
				Gender:    true,
				Phone:     "555-123-4567",
				Email:     "yuki.takahashi@japan.com",
				Expertise: "Orthopedics",
				Schedule: []dao.Schedule{
					{
						Day:       "Wednesday",
						StartTime: dao.Time{Hour: 8, Minute: 0},
						EndTime:   dao.Time{Hour: 12, Minute: 0},
					},
				},
			},
			{
				ID:        4,
				FirstName: "Amir",
				LastName:  "Khosravi",
				Gender:    false,
				Phone:     "222-333-4444",
				Email:     "amir.khosravi@iran.com",
				Expertise: "Gastroenterology",
				Schedule: []dao.Schedule{
					{
						Day:       "Thursday",
						StartTime: dao.Time{Hour: 9, Minute: 30},
						EndTime:   dao.Time{Hour: 17, Minute: 30},
					},
				},
			},
			{
				ID:        5,
				FirstName: "Amina",
				LastName:  "Ndiaye",
				Gender:    true,
				Phone:     "555-987-6543",
				Email:     "amina.ndiaye@senegal.com",
				Expertise: "Pediatrics",
				Schedule: []dao.Schedule{
					{
						Day:       "Friday",
						StartTime: dao.Time{Hour: 8, Minute: 0},
						EndTime:   dao.Time{Hour: 14, Minute: 0},
					},
				},
			},
		}

		response := dto.ScheduleResponse{
			Doctors: doctors,
		}

		return c.XML(response)
	})

	app.Listen(":6969")
}
