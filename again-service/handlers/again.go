package handlers

import (
	"crypto/tls"
	"io/ioutil"
	"net"
	"net/http"
	"strings"

	"golang.org/x/net/http2"

	"github.com/labstack/echo/v4"
	"github.com/openzipkin/zipkin-go/propagation/b3"
)

// TODO: instrument http client with metrics
type AgainHandler struct {
	HelloServiceURL string
}

var h2cClient = http.Client{
	Transport: &http2.Transport{
		AllowHTTP: true,
		DialTLS: func(network, addr string, cfg *tls.Config) (net.Conn, error) {
			return net.Dial(network, addr)
		},
	},
}

func (a *AgainHandler) Handle(c echo.Context) error {
	req, err := http.NewRequest("GET", a.HelloServiceURL, nil)

	sc, err := b3.ExtractHTTP(c.Request())()
	if err == nil {
		b3.InjectHTTP(req, b3.WithSingleAndMultiHeader())(*sc)
	}

	resp, err := h2cClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	respBody := strings.Split(string(body), "\n")[0] + ", again"
	return c.String(http.StatusOK, respBody)
}
