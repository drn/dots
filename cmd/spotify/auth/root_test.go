package auth

import (
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
)

// callback fires an HTTP GET against the loopback server to simulate Spotify
// redirecting back with the given query string.
func callback(t *testing.T, addr, query string) func() {
	t.Helper()
	return func() {
		go func() {
			resp, err := http.Get("http://" + addr + "/callback?" + query)
			if err == nil {
				resp.Body.Close()
			}
		}()
	}
}

func loopbackListener(t *testing.T) (net.Listener, string) {
	t.Helper()
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	return listener, listener.Addr().String()
}

func TestCaptureAuthCode_Success(t *testing.T) {
	listener, addr := loopbackListener(t)

	code, err := captureAuthCode(listener, "/callback", "state-123",
		callback(t, addr, "code=auth-code&state=state-123"))

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if code != "auth-code" {
		t.Errorf("code = %q, want auth-code", code)
	}
}

func TestCaptureAuthCode_StateMismatch(t *testing.T) {
	listener, addr := loopbackListener(t)

	_, err := captureAuthCode(listener, "/callback", "want",
		callback(t, addr, "code=auth-code&state=evil"))

	if err == nil {
		t.Fatal("expected error on state mismatch, got nil")
	}
}

func TestCaptureAuthCode_AuthDenied(t *testing.T) {
	listener, addr := loopbackListener(t)

	_, err := captureAuthCode(listener, "/callback", "want",
		callback(t, addr, "error=access_denied&state=want"))

	if err == nil {
		t.Fatal("expected error when callback reports failure, got nil")
	}
	if !strings.Contains(err.Error(), "access_denied") {
		t.Errorf("error = %q, want it to mention access_denied", err)
	}
}

func TestCaptureAuthCode_MissingCode(t *testing.T) {
	listener, addr := loopbackListener(t)

	_, err := captureAuthCode(listener, "/callback", "want",
		callback(t, addr, "state=want"))

	if err == nil {
		t.Fatal("expected error when code is missing, got nil")
	}
}

func TestCallbackPath_DefaultsToRoot(t *testing.T) {
	noPath, _ := url.Parse("http://127.0.0.1:8888")
	if got := callbackPath(noPath); got != "/" {
		t.Errorf("callbackPath(no path) = %q, want /", got)
	}

	withPath, _ := url.Parse("http://127.0.0.1:8888/callback")
	if got := callbackPath(withPath); got != "/callback" {
		t.Errorf("callbackPath(/callback) = %q, want /callback", got)
	}
}

func TestRandomState_UniqueAndHex(t *testing.T) {
	a, err := randomState()
	if err != nil {
		t.Fatalf("randomState: %v", err)
	}
	b, err := randomState()
	if err != nil {
		t.Fatalf("randomState: %v", err)
	}
	if a == b {
		t.Errorf("randomState produced identical values: %q", a)
	}
	if len(a) != 32 {
		t.Errorf("len = %d, want 32 hex chars", len(a))
	}
}

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
