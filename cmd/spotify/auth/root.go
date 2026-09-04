// Package auth manages Spotify API auth
package auth

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"strings"
	"sync"
	"time"

	"github.com/drn/dots/cli/config"
	"github.com/drn/dots/pkg/log"
	jsoniter "github.com/json-iterator/go"
)

// spotifyTokenURL is a var (not const) so tests can point it at a local
// httptest server.
var spotifyTokenURL = "https://accounts.spotify.com/api/token"

// authTimeout bounds how long the CLI waits for the user to complete the
// browser consent flow before giving up.
const authTimeout = 2 * time.Minute

// httpClient bounds Spotify API calls to a reasonable interactive timeout so
// the CLI can't hang on a stalled connection.
var httpClient = &http.Client{Timeout: 10 * time.Second}

// FetchAccessToken - Returns a valid access token for the Spotify API.
// * If no cached access token or refresh token
//   - Starts a local loopback server on the redirect URI's port
//   - Opens browser to authorization URL
//   - Captures the authorization code from the OAuth callback automatically
//   - Exchanges authorization code for access token and refresh token
//
// * If access token is expired
//   - Exchange refresh token for a new access token
//   - If the refresh token itself was revoked or expired, clear the stale
//     cache and fall back to a full interactive re-authorization rather than
//     exiting on a bare API error
func FetchAccessToken() string {
	accessToken := config.Read("spotify.access_token")
	refreshToken := config.Read("spotify.refresh_token")

	if accessToken == "" || refreshToken == "" {
		accessToken, refreshToken = exchangeAuthorizationCode(authorize())
		config.Write("spotify.access_token", accessToken)
		config.Write("spotify.refresh_token", refreshToken)
		return accessToken
	}

	if refreshNeeded(accessToken) {
		newAccessToken, ok := exchangeRefreshToken(refreshToken)
		if !ok {
			log.Warning("Spotify refresh token revoked or expired; re-authorizing")
			config.Delete("spotify.access_token")
			config.Delete("spotify.refresh_token")
			return FetchAccessToken()
		}
		accessToken = newAccessToken
		config.Write("spotify.access_token", accessToken)
	}

	return accessToken
}

// authorize runs the OAuth authorization-code flow using a loopback redirect.
// SPOTIFY_REDIRECT_URI must be a loopback URL with an explicit port (e.g.
// http://127.0.0.1:8888/callback) that is also registered on the Spotify app.
// It starts a local HTTP server on that port, opens the browser to Spotify's
// consent screen, and blocks until Spotify redirects back with an
// authorization code, returning that code.
func authorize() string {
	redirectURI := os.Getenv("SPOTIFY_REDIRECT_URI")
	redirect, err := url.Parse(redirectURI)
	if err != nil || redirect.Port() == "" || !isLoopback(redirect.Hostname()) {
		log.Error(
			"SPOTIFY_REDIRECT_URI must be a loopback URL with a port, "+
				"e.g. http://127.0.0.1:8888/callback (got %q)", redirectURI,
		)
		os.Exit(1)
	}

	state, err := randomState()
	if err != nil {
		log.Error("could not generate OAuth state: %s", err)
		os.Exit(1)
	}

	// Bind to the redirect's own host:port so the listener matches the address
	// the browser will be redirected to.
	addr := net.JoinHostPort(redirect.Hostname(), redirect.Port())
	listener, err := net.Listen("tcp", addr)
	if err != nil {
		log.Error("could not start local server on %s: %s", addr, err)
		os.Exit(1)
	}

	params := url.Values{
		"response_type": {"code"},
		"client_id":     {os.Getenv("SPOTIFY_CLIENT_ID")},
		"redirect_uri":  {redirectURI},
		"scope": {
			strings.Join([]string{
				"user-read-currently-playing",
				"user-library-read",
				"user-library-modify",
			}, " "),
		},
		"state": {state},
	}
	authURL := "https://accounts.spotify.com/authorize?" + params.Encode()

	code, err := captureAuthCode(listener, callbackPath(redirect), state, func() {
		fmt.Println("Opening browser to authorize Spotify…")
		// Launch the browser without a shell so the auth URL is never
		// interpreted by zsh.
		if execErr := exec.Command("open", authURL).Start(); execErr != nil {
			log.Warning("could not open browser automatically; visit:\n%s", authURL)
		}
	})
	if err != nil {
		log.Error("%s", err)
		os.Exit(1)
	}
	return code
}

// isLoopback reports whether host is a loopback address Spotify will redirect
// back to and that we can safely bind a local server on.
func isLoopback(host string) bool {
	if host == "localhost" {
		return true
	}
	ip := net.ParseIP(host)
	return ip != nil && ip.IsLoopback()
}

// callbackPath returns the path the loopback server should listen on, defaulting
// to "/" when the redirect URI has no path (http.ServeMux rejects an empty
// pattern).
func callbackPath(redirect *url.URL) string {
	if redirect.Path == "" {
		return "/"
	}
	return redirect.Path
}

// captureAuthCode serves the OAuth callback on listener, runs open() to launch
// the browser, and blocks until Spotify redirects back. The wantState value
// guards against CSRF. It returns the authorization code, or an error if the
// callback reports failure, the state mismatches, or the timeout elapses.
func captureAuthCode(listener net.Listener, path, wantState string, open func()) (string, error) {
	type result struct {
		code string
		err  error
	}
	results := make(chan result, 1)

	// once ensures only the first callback delivers a result; a browser retry
	// or refresh that hits the handler again is answered without blocking on a
	// channel send that no one is waiting to receive.
	var once sync.Once
	deliver := func(res result) {
		once.Do(func() { results <- res })
	}

	mux := http.NewServeMux()
	mux.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
		query := r.URL.Query()
		switch {
		case query.Get("error") != "":
			http.Error(w, "Spotify authorization failed.", http.StatusBadRequest)
			deliver(result{err: fmt.Errorf("authorization denied: %s", query.Get("error"))})
		case query.Get("state") != wantState:
			http.Error(w, "State mismatch.", http.StatusBadRequest)
			deliver(result{err: errors.New("state mismatch in OAuth callback")})
		case query.Get("code") == "":
			http.Error(w, "Missing authorization code.", http.StatusBadRequest)
			deliver(result{err: errors.New("missing authorization code in OAuth callback")})
		default:
			io.WriteString(w, "Spotify authorization complete — you can close this tab.")
			if flusher, ok := w.(http.Flusher); ok {
				flusher.Flush()
			}
			deliver(result{code: query.Get("code")})
		}
	})

	server := &http.Server{Handler: mux}
	go server.Serve(listener)
	// Shut down gracefully so the handler's "you can close this tab" response
	// finishes flushing to the browser before the connection is torn down.
	defer func() {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		if err := server.Shutdown(ctx); err != nil {
			server.Close()
		}
	}()

	open()

	select {
	case res := <-results:
		return res.code, res.err
	case <-time.After(authTimeout):
		return "", errors.New("timed out waiting for Spotify authorization")
	}
}

// randomState returns a cryptographically random hex string used as the OAuth
// state parameter to defend against CSRF on the callback.
func randomState() (string, error) {
	buf := make([]byte, 16)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return hex.EncodeToString(buf), nil
}

func refreshNeeded(accessToken string) bool {
	_, status := SendRequest(http.MethodGet, "https://api.spotify.com/v1/me", Headers(accessToken), nil, nil)
	return status == http.StatusUnauthorized
}

// Headers returns the standard Spotify API request headers.
func Headers(accessToken string) http.Header {
	return http.Header{
		"Accept":        {"application/json"},
		"Content-Type":  {"application/json"},
		"Authorization": {"Bearer " + accessToken},
	}
}

func exchangeAuthorizationCode(code string) (string, string) {
	data, status := exchangeToken(url.Values{
		"code":       {code},
		"grant_type": {"authorization_code"},
	})
	if status != http.StatusOK {
		fmt.Println(string(data))
		os.Exit(1)
	}
	return jsoniter.Get(data, "access_token").ToString(),
		jsoniter.Get(data, "refresh_token").ToString()
}

// exchangeRefreshToken exchanges refreshToken for a new access token. It
// returns ok=false (instead of exiting) when Spotify rejects the exchange, so
// callers can distinguish "refresh token revoked/expired" from a fatal error
// and fall back to re-authorization.
func exchangeRefreshToken(refreshToken string) (string, bool) {
	data, status := exchangeToken(url.Values{
		"refresh_token": {refreshToken},
		"grant_type":    {"refresh_token"},
	})
	if status != http.StatusOK {
		return "", false
	}
	return jsoniter.Get(data, "access_token").ToString(), true
}

func exchangeToken(params url.Values) ([]byte, int) {
	form := url.Values{}
	for k, v := range params {
		form[k] = v
	}
	form.Set("client_id", os.Getenv("SPOTIFY_CLIENT_ID"))
	form.Set("client_secret", os.Getenv("SPOTIFY_CLIENT_SECRET"))
	form.Set("redirect_uri", os.Getenv("SPOTIFY_REDIRECT_URI"))

	headers := http.Header{"Content-Type": {"application/x-www-form-urlencoded"}}
	return SendRequest(
		http.MethodPost, spotifyTokenURL, headers, nil, strings.NewReader(form.Encode()),
	)
}

// SendRequest performs an HTTP request with optional query params and body,
// returning the response body and status code. Exits on transport errors.
func SendRequest(
	method, baseURL string,
	headers http.Header,
	query url.Values,
	body io.Reader,
) ([]byte, int) {
	fullURL := baseURL
	if len(query) > 0 {
		fullURL = baseURL + "?" + query.Encode()
	}
	request, err := http.NewRequest(method, fullURL, body)
	HandleRequestError(err)
	if headers != nil {
		request.Header = headers
	}

	response, err := httpClient.Do(request)
	HandleRequestError(err)
	defer response.Body.Close()

	data, err := io.ReadAll(response.Body)
	HandleRequestError(err)
	return data, response.StatusCode
}

// HandleRequestError exits if the error is non-nil.
func HandleRequestError(err error) {
	if err == nil {
		return
	}
	fmt.Println(err)
	os.Exit(1)
}
