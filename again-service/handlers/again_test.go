package handlers

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
)

func TestAgainHandler(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Hello World")
	}))
	ts.Config.Handler = h2c.NewHandler(ts.Config.Handler, &http2.Server{})
	defer ts.Close()

	req := httptest.NewRequest(echo.GET, "/", nil)
	rec := httptest.NewRecorder()
	c := echo.New().NewContext(req, rec)

	a := &AgainHandler{HelloServiceURL: ts.URL}
	err := a.Handle(c)
	assert.NoError(t, err)

	if assert.Equal(t, http.StatusOK, rec.Code) {
		m := string(rec.Body.Bytes())
		assert.Equal(t, m, "Hello World, again")
	}
}
