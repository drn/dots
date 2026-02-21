// Package auth manages Spotify API auth
package auth

import (
	"bytes"
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
	var buffer bytes.Buffer
	buffer.WriteString("https://accounts.spotify.com/authorize?")
	params := url.Values{
		"response_type": {"code"},
		"client_id":     {os.Getenv("SPOTIFY_CLIENT_ID")},
		"redirect_uri":  {"https://console.drn.dev/"},
		"scope": {
			strings.Join([]string{
				"user-read-currently-playing",
				"user-library-read",
				"user-library-modify",
			}, " "),
		},
		"state": {"spotify"},
	}
	buffer.WriteString(params.Encode())
	url := buffer.String()
	run.Execute(`open "` + url + `"`)
}

func refreshNeeded(accessToken string) bool {
	url := "https://api.spotify.com/v1/me"
	response, err := req.Put(url, headers(accessToken))
	handleRequestError(err)
	return response.Response().StatusCode == 401
}

func headers(accessToken string) req.Header {
	return req.Header{
		"Accept":        "application/json",
		"Content-Type":  "application/json",
		"Authorization": fmt.Sprintf("Bearer %s", accessToken),
	}
}

func exchangeAuthorizationCode(code string) (string, string) {
	url := "https://accounts.spotify.com/api/token"

	params := req.Param{
		"code":          code,
		"grant_type":    "authorization_code",
		"client_id":     os.Getenv("SPOTIFY_CLIENT_ID"),
		"client_secret": os.Getenv("SPOTIFY_CLIENT_SECRET"),
		"redirect_uri":  "https://console.drn.dev/",
	}

	response, err := req.Post(url, params)
	handleRequestError(err)

	if response.Response().StatusCode != 200 {
		fmt.Println(string(response.Bytes()))
		os.Exit(1)
	}
	accessToken := jsoniter.Get(response.Bytes(), "access_token").ToString()
	refreshToken := jsoniter.Get(response.Bytes(), "refresh_token").ToString()

	return accessToken, refreshToken
}

func exchangeRefreshToken(code string) string {
	url := "https://accounts.spotify.com/api/token"

	params := req.Param{
		"refresh_token": code,
		"grant_type":    "refresh_token",
		"client_id":     os.Getenv("SPOTIFY_CLIENT_ID"),
		"client_secret": os.Getenv("SPOTIFY_CLIENT_SECRET"),
		"redirect_uri":  "https://console.drn.dev/",
	}

	response, err := req.Post(url, params)
	handleRequestError(err)

	if response.Response().StatusCode != 200 {
		fmt.Println(string(response.Bytes()))
		os.Exit(1)
	}
	accessToken := jsoniter.Get(response.Bytes(), "access_token").ToString()

	return accessToken
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

func handleRequestError(err error) {
	if err == nil {
		return
	}
	fmt.Println(err)
	os.Exit(1)
}
