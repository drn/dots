package auth

import (
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
)

func TestSendRequest_GET_NoQueryNoBody(t *testing.T) {
	var (
		gotMethod string
		gotPath   string
		gotQuery  string
	)
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotMethod = r.Method
		gotPath = r.URL.Path
		gotQuery = r.URL.RawQuery
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"ok":true}`))
	}))
	defer server.Close()

	data, status := SendRequest(http.MethodGet, server.URL+"/me", nil, nil, nil)

	if gotMethod != http.MethodGet {
		t.Errorf("method = %q, want GET", gotMethod)
	}
	if gotPath != "/me" {
		t.Errorf("path = %q, want /me", gotPath)
	}
	if gotQuery != "" {
		t.Errorf("query = %q, want empty", gotQuery)
	}
	if status != http.StatusOK {
		t.Errorf("status = %d, want 200", status)
	}
	if string(data) != `{"ok":true}` {
		t.Errorf("body = %q, want %q", string(data), `{"ok":true}`)
	}
}

func TestSendRequest_QueryParamsEncoded(t *testing.T) {
	var gotQuery url.Values
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotQuery = r.URL.Query()
		w.WriteHeader(http.StatusOK)
	}))
	defer server.Close()

	params := url.Values{"ids": {"abc"}, "market": {"US"}}
	_, _ = SendRequest(http.MethodGet, server.URL+"/tracks", nil, params, nil)

	if gotQuery.Get("ids") != "abc" {
		t.Errorf("ids = %q, want abc", gotQuery.Get("ids"))
	}
	if gotQuery.Get("market") != "US" {
		t.Errorf("market = %q, want US", gotQuery.Get("market"))
	}
}

func TestSendRequest_HeadersAndBody(t *testing.T) {
	var (
		gotAuth        string
		gotContentType string
		gotBody        string
	)
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotAuth = r.Header.Get("Authorization")
		gotContentType = r.Header.Get("Content-Type")
		b, _ := io.ReadAll(r.Body)
		gotBody = string(b)
		w.WriteHeader(http.StatusNoContent)
	}))
	defer server.Close()

	headers := Headers("token-123")
	_, status := SendRequest(
		http.MethodPut, server.URL+"/player", headers, nil, strings.NewReader(`{"x":1}`),
	)

	if gotAuth != "Bearer token-123" {
		t.Errorf("Authorization = %q, want %q", gotAuth, "Bearer token-123")
	}
	if gotContentType != "application/json" {
		t.Errorf("Content-Type = %q, want application/json", gotContentType)
	}
	if gotBody != `{"x":1}` {
		t.Errorf("body = %q, want %q", gotBody, `{"x":1}`)
	}
	if status != http.StatusNoContent {
		t.Errorf("status = %d, want 204", status)
	}
}

func TestSendRequest_StatusCodePassthrough(t *testing.T) {
	var gotMethod string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotMethod = r.Method
		w.WriteHeader(http.StatusUnauthorized)
	}))
	defer server.Close()

	_, status := SendRequest(http.MethodPut, server.URL, nil, nil, nil)
	if gotMethod != http.MethodPut {
		t.Errorf("method = %q, want PUT", gotMethod)
	}
	if status != http.StatusUnauthorized {
		t.Errorf("status = %d, want 401", status)
	}
}

func TestHeaders_AllFieldsSet(t *testing.T) {
	h := Headers("xyz")
	if got := h.Get("Accept"); got != "application/json" {
		t.Errorf("Accept = %q, want application/json", got)
	}
	if got := h.Get("Content-Type"); got != "application/json" {
		t.Errorf("Content-Type = %q, want application/json", got)
	}
	if got := h.Get("Authorization"); got != "Bearer xyz" {
		t.Errorf("Authorization = %q, want %q", got, "Bearer xyz")
	}
}
