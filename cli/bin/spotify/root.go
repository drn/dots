// Requires creation of a Spotify API application here:
//   https://developer.spotify.com/dashboard/applications
//   Redirect URI: https://console.drn.dev/
// The following ENV variables must exist:
//   SPOTIFY_CLIENT_ID
//   SPOTIFY_CLIENT_SECRET

package main

import (
	"bytes"
	"errors"
	"fmt"
	"net/url"
	"os"
	"strings"

	"github.com/drn/dots/cli/config"
	"github.com/drn/dots/cli/log"
	"github.com/drn/dots/cli/run"
	"github.com/imroc/req"
	jsoniter "github.com/json-iterator/go"
	"github.com/manifoldco/promptui"
)

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
		Label:    "Inputs Access Code:",
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
		return errors.New("Must not be blank")
	}
	return nil
}

func main() {
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

	trackID, trackName, trackArtist := currentTrackInfo(accessToken)

	if trackID == "" {
		log.Error("No current track playing")
		os.Exit(1)
	}

	if isTrackSaved(accessToken, trackID) {
		log.Info("[−]\n%s\n%s", trackName, trackArtist)
		removeTrack(accessToken, trackID)
	} else {
		log.Info("[+]\n%s\n%s", trackName, trackArtist)
		saveTrack(accessToken, trackID)
	}
}

func refreshNeeded(accessToken string) bool {
	url := "https://api.spotify.com/v1/me"
	response, err := req.Put(url, headers(accessToken))
	handleRequestError(err)
	return response.Response().StatusCode == 401
}

// https://developer.spotify.com/documentation/web-api/reference/library/save-tracks-user/
func saveTrack(accessToken string, trackID string) {
	url := "https://api.spotify.com/v1/me/tracks"

	params := req.QueryParam{"ids": trackID}
	response, err := req.Put(url, headers(accessToken), params)
	handleRequestError(err)
	if response.Response().StatusCode != 200 {
		log.Error("Failed to save track")
		os.Exit(1)
	}
}

// https://developer.spotify.com/documentation/web-api/reference/library/remove-tracks-user/
func removeTrack(accessToken string, trackID string) {
	url := "https://api.spotify.com/v1/me/tracks"

	params := req.QueryParam{"ids": trackID}
	response, err := req.Delete(url, headers(accessToken), params)
	handleRequestError(err)
	if response.Response().StatusCode != 200 {
		log.Error("Failed to remove track")
		os.Exit(1)
	}
}

// https://developer.spotify.com/documentation/web-api/reference/library/check-users-saved-tracks/
func isTrackSaved(accessToken string, trackID string) bool {
	url := "https://api.spotify.com/v1/me/tracks/contains"

	params := req.Param{"ids": trackID}
	response, err := req.Get(url, headers(accessToken), params)
	handleRequestError(err)

	return jsoniter.Get(response.Bytes(), 0).ToBool()
}

// https://developer.spotify.com/documentation/web-api/reference/player/get-the-users-currently-playing-track/
func currentTrackInfo(accessToken string) (string, string, string) {
	url := "https://api.spotify.com/v1/me/player/currently-playing"

	response, err := req.Get(url, headers(accessToken))
	handleRequestError(err)
	id := jsoniter.Get(response.Bytes(), "item", "id").ToString()
	name := jsoniter.Get(response.Bytes(), "item", "name").ToString()
	artist := jsoniter.Get(response.Bytes(), "item", "artists", 0, "name").ToString()

	return id, name, artist
}

func handleRequestError(err error) {
	if err == nil {
		return
	}
	fmt.Println(err)
	os.Exit(1)
}

func headers(accessToken string) req.Header {
	return req.Header{
		"Accept":        "application/json",
		"Content-Type":  "application/json",
		"Authorization": fmt.Sprintf("Bearer %s", accessToken),
	}
}
