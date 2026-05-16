// Package auth manages Spotify API auth
package auth

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"

	"github.com/drn/dots/cli/config"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
	jsoniter "github.com/json-iterator/go"
	"github.com/manifoldco/promptui"
)

const spotifyTokenURL = "https://accounts.spotify.com/api/token"

// FetchAccessToken - Returns a valid access token for the Spotify API.
// * If no cached access token or refresh token
//   * Opens browser to authorization URL
//   * Accepts user input of authorization code
//   * Exchanges authorization code for access token and refresh token
// * If access token is expired
//   * Exchange refresh token for a new access token
func FetchAccessToken() string {
	accessToken := config.Read("spotify.access_token")
	refreshToken := config.Read("spotify.refresh_token")

	if accessToken == "" || refreshToken == "" {
		authorize()
		accessToken, refreshToken = exchangeAuthorizationCode(inputCode())
		config.Write("spotify.access_token", accessToken)
		config.Write("spotify.refresh_token", refreshToken)
	} else if refreshNeeded(accessToken) {
		// refresh access token using refresh token
		accessToken = exchangeRefreshToken(refreshToken)
		config.Write("spotify.access_token", accessToken)
	}

	return accessToken
}

func authorize() {
	params := url.Values{
		"response_type": {"code"},
		"client_id":     {os.Getenv("SPOTIFY_CLIENT_ID")},
		"redirect_uri":  {os.Getenv("SPOTIFY_REDIRECT_URI")},
		"scope": {
			strings.Join([]string{
				"user-read-currently-playing",
				"user-library-read",
				"user-library-modify",
			}, " "),
		},
		"state": {"spotify"},
	}
	authURL := "https://accounts.spotify.com/authorize?" + params.Encode()
	run.Execute(`open "` + authURL + `"`)
}

func refreshNeeded(accessToken string) bool {
	_, status := SendRequest(http.MethodPut, "https://api.spotify.com/v1/me", Headers(accessToken), nil, nil)
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

func exchangeRefreshToken(code string) string {
	data := exchangeToken(url.Values{
		"refresh_token": {code},
		"grant_type":    {"refresh_token"},
	})
	return jsoniter.Get(data, "access_token").ToString()
}

func exchangeToken(params url.Values) []byte {
	params.Set("client_id", os.Getenv("SPOTIFY_CLIENT_ID"))
	params.Set("client_secret", os.Getenv("SPOTIFY_CLIENT_SECRET"))
	params.Set("redirect_uri", os.Getenv("SPOTIFY_REDIRECT_URI"))

	headers := http.Header{"Content-Type": {"application/x-www-form-urlencoded"}}
	data, status := SendRequest(
		http.MethodPost, spotifyTokenURL, headers, nil, strings.NewReader(params.Encode()),
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

	response, err := http.DefaultClient.Do(request)
	HandleRequestError(err)
	defer response.Body.Close()

	data, err := io.ReadAll(response.Body)
	HandleRequestError(err)
	return data, response.StatusCode
}

func inputCode() string {
	prompt := promptui.Prompt{
		Label:    "Authorization code",
		Validate: validateInput,
	}

	value, err := prompt.Run()
	if err != nil {
		log.Error("%s", err)
		os.Exit(1)
	}
	return value
}

func validateInput(input string) error {
	if strings.TrimSpace(input) == "" {
		return errors.New("must not be blank")
	}
	return nil
}

// HandleRequestError exits if the error is non-nil.
func HandleRequestError(err error) {
	if err == nil {
		return
	}
	fmt.Println(err)
	os.Exit(1)
}
