// Package auth manages Spotify API auth
package auth

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"github.com/drn/dots/cli/config"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
	jsoniter "github.com/json-iterator/go"
)

const spotifyTokenURL = "https://accounts.spotify.com/api/token"

// authTimeout bounds how long the CLI waits for the user to complete the
// browser consent flow before giving up.
const authTimeout = 2 * time.Minute

// httpClient bounds Spotify API calls to a reasonable interactive timeout so
// the CLI can't hang on a stalled connection.
var httpClient = &http.Client{Timeout: 10 * time.Second}

// FetchAccessToken - Returns a valid access token for the Spotify API.
// * If no cached access token or refresh token
//   * Starts a local loopback server on the redirect URI's port
//   * Opens browser to authorization URL
//   * Captures the authorization code from the OAuth callback automatically
//   * Exchanges authorization code for access token and refresh token
// * If access token is expired
//   * Exchange refresh token for a new access token
func FetchAccessToken() string {
	accessToken := config.Read("spotify.access_token")
	refreshToken := config.Read("spotify.refresh_token")

	if accessToken == "" || refreshToken == "" {
		accessToken, refreshToken = exchangeAuthorizationCode(authorize())
		config.Write("spotify.access_token", accessToken)
		config.Write("spotify.refresh_token", refreshToken)
	} else if refreshNeeded(accessToken) {
		// refresh access token using refresh token
		accessToken = exchangeRefreshToken(refreshToken)
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
	if err != nil || redirect.Port() == "" {
		log.Error(
			"SPOTIFY_REDIRECT_URI must be a loopback URL with a port, "+
				"e.g. http://127.0.0.1:8888/callback (got %q)", redirectURI,
		)
		os.Exit(1)
	}

	state, err := randomState()
	HandleRequestError(err)

	listener, err := net.Listen("tcp", "127.0.0.1:"+redirect.Port())
	HandleRequestError(err)

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
		run.Execute(`open "` + authURL + `"`)
	})
	if err != nil {
		log.Error("%s", err)
		os.Exit(1)
	}
	return code
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

	mux := http.NewServeMux()
	mux.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
		query := r.URL.Query()
		switch {
		case query.Get("error") != "":
			http.Error(w, "Spotify authorization failed.", http.StatusBadRequest)
			results <- result{err: fmt.Errorf("authorization denied: %s", query.Get("error"))}
		case query.Get("state") != wantState:
			http.Error(w, "State mismatch.", http.StatusBadRequest)
			results <- result{err: errors.New("state mismatch in OAuth callback")}
		case query.Get("code") == "":
			http.Error(w, "Missing authorization code.", http.StatusBadRequest)
			results <- result{err: errors.New("missing authorization code in OAuth callback")}
		default:
			io.WriteString(w, "Spotify authorization complete — you can close this tab.")
			if flusher, ok := w.(http.Flusher); ok {
				flusher.Flush()
			}
			results <- result{code: query.Get("code")}
		}
	})

	server := &http.Server{Handler: mux}
	go server.Serve(listener)
	defer server.Close()

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
	data := exchangeToken(url.Values{
		"code":       {code},
		"grant_type": {"authorization_code"},
	})
	return jsoniter.Get(data, "access_token").ToString(),
		jsoniter.Get(data, "refresh_token").ToString()
}

func exchangeRefreshToken(refreshToken string) string {
	data := exchangeToken(url.Values{
		"refresh_token": {refreshToken},
		"grant_type":    {"refresh_token"},
	})
	return jsoniter.Get(data, "access_token").ToString()
}

func exchangeToken(params url.Values) []byte {
	form := url.Values{}
	for k, v := range params {
		form[k] = v
	}
	form.Set("client_id", os.Getenv("SPOTIFY_CLIENT_ID"))
	form.Set("client_secret", os.Getenv("SPOTIFY_CLIENT_SECRET"))
	form.Set("redirect_uri", os.Getenv("SPOTIFY_REDIRECT_URI"))

	headers := http.Header{"Content-Type": {"application/x-www-form-urlencoded"}}
	data, status := SendRequest(
		http.MethodPost, spotifyTokenURL, headers, nil, strings.NewReader(form.Encode()),
	)
	if status != http.StatusOK {
		fmt.Println(string(data))
		os.Exit(1)
	}
	return data
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
