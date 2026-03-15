// Package auth manages Spotify API auth
package auth

import (
	"errors"
	"fmt"
	"net/url"
	"os"
	"strings"

	"github.com/drn/dots/cli/config"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/run"
	"github.com/imroc/req"
	jsoniter "github.com/json-iterator/go"
	"github.com/manifoldco/promptui"
)

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
	url := "https://api.spotify.com/v1/me"
	response, err := req.Put(url, Headers(accessToken))
	HandleRequestError(err)
	return response.Response().StatusCode == 401
}

// Headers returns the standard Spotify API request headers.
func Headers(accessToken string) req.Header {
	return req.Header{
		"Accept":        "application/json",
		"Content-Type":  "application/json",
		"Authorization": "Bearer " + accessToken,
	}
}

const spotifyTokenURL = "https://accounts.spotify.com/api/token"

func exchangeAuthorizationCode(code string) (string, string) {
	data := exchangeToken(req.Param{
		"code":       code,
		"grant_type": "authorization_code",
	})
	return jsoniter.Get(data, "access_token").ToString(),
		jsoniter.Get(data, "refresh_token").ToString()
}

func exchangeRefreshToken(code string) string {
	data := exchangeToken(req.Param{
		"refresh_token": code,
		"grant_type":    "refresh_token",
	})
	return jsoniter.Get(data, "access_token").ToString()
}

func exchangeToken(params req.Param) []byte {
	params["client_id"] = os.Getenv("SPOTIFY_CLIENT_ID")
	params["client_secret"] = os.Getenv("SPOTIFY_CLIENT_SECRET")
	params["redirect_uri"] = os.Getenv("SPOTIFY_REDIRECT_URI")

	response, err := req.Post(spotifyTokenURL, params)
	HandleRequestError(err)

	if response.Response().StatusCode != 200 {
		fmt.Println(string(response.Bytes()))
		os.Exit(1)
	}
	return response.Bytes()
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
