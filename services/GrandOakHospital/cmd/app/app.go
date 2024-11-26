package main

import (
	"fmt"

	"github.com/gofiber/fiber/v2"
)

func main() {
	app := fiber.New()

	app.Get("/alivecheck", func(c *fiber.Ctx) error {
		fmt.Print("Request received!\n")
		return c.SendString("ok")
	})

	app.Listen(":6969")
}
