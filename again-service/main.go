package main

import (
	"net/http"
	"os"

	"golang.org/x/net/http2"

	"github.com/nabam/dsoc/again-service/handlers"

	"github.com/labstack/echo-contrib/prometheus"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func instrument(e *echo.Echo) {
	e.HideBanner = true

	e.Use(middleware.Logger())

	e.GET("/health", func(c echo.Context) error { return c.String(http.StatusOK, "alive") })

	p := prometheus.NewPrometheus("http", nil)
	p.Use(e)
}

func main() {
	helloWorldService := os.Getenv("HELLO_WORLD_SERVICE")

	e := echo.New()
	instrument(e)

	a := &handlers.AgainHandler{HelloServiceURL: helloWorldService}
	e.GET("/", a.Handle)

	h2s := &http2.Server{}
	e.Logger.Fatal(e.StartH2CServer(":8080", h2s))
}
