package main

import (
	"net/http"

	"golang.org/x/net/http2"

	"github.com/nabam/dsoc/hello-world-service/handlers"

	"github.com/labstack/echo-contrib/prometheus"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func main() {
	e := echo.New()
	e.HideBanner = true
	e.Use(middleware.Logger())
	p := prometheus.NewPrometheus("http", nil)
	p.Use(e)
	e.GET("/health", func(c echo.Context) error { return c.String(http.StatusOK, "alive") })

	e.GET("/", handlers.Hello)

	h2s := &http2.Server{}
	e.Logger.Fatal(e.StartH2CServer(":8080", h2s))
}
