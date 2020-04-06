// Requires creation of a Spotify API application here:
//   https://developer.spotify.com/dashboard/applications
//   Redirect URI: https://console.drn.dev/
// The following ENV variables must exist:
//   SPOTIFY_CLIENT_ID
//   SPOTIFY_CLIENT_SECRET

package main

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"net/http"
	"os"
	"strings"

	"github.com/drn/dots/cli/config"
	"github.com/drn/dots/cli/log"
	"github.com/drn/dots/cli/run"
	"github.com/imroc/req"
	jsoniter "github.com/json-iterator/go"
	"github.com/manifoldco/promptui"
	"golang.org/x/oauth2"
)

const (
	// AuthURL is the URL to Spotify Accounts Service's OAuth2 endpoint.
	AuthURL = "https://accounts.spotify.com/authorize"
	// TokenURL is the URL to the Spotify Accounts Service's OAuth2
	// token endpoint.
	TokenURL = "https://accounts.spotify.com/api/token"
)

func authorize(config *oauth2.Config) {
	run.Execute(`open "` + config.AuthCodeURL("spotify") + `"`)
}

func oauth() oauth2.Config {
	return oauth2.Config{
		ClientID:     os.Getenv("SPOTIFY_CLIENT_ID"),
		ClientSecret: os.Getenv("SPOTIFY_CLIENT_SECRET"),
		RedirectURL:  "https://console.drn.dev/",
		Scopes: []string{
			"user-read-currently-playing",
			"user-library-read",
			"user-library-modify",
		},
		Endpoint: oauth2.Endpoint{
			AuthURL:  AuthURL,
			TokenURL: TokenURL,
		},
	}
}

func exchange(oauth *oauth2.Config, code string) (*oauth2.Token, error) {
	// disable HTTP/2 for DefaultClient,
	// see: https://github.com/zmb3/spotify/issues/20
	tr := &http.Transport{
		TLSNextProto: map[string]func(
			authority string, c *tls.Conn,
		) http.RoundTripper{},
	}
	ctx := context.WithValue(
		context.Background(),
		oauth2.HTTPClient,
		&http.Client{Transport: tr},
	)
	return oauth.Exchange(ctx, code)
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
		// configure oauth2 client
		oauth := oauth()

		// fetch access code
		authorize(&oauth)

		code := inputCode()

		token, err := exchange(&oauth, code)

		if err != nil {
			log.Error("%s", err)
			os.Exit(1)
		}

		fmt.Println()

		accessToken = token.AccessToken
		refreshToken = token.RefreshToken
		fmt.Printf("Access Token: %s\n", accessToken)
		fmt.Printf("Refresh Token: %s\n", refreshToken)

		config.Write("spotify.access_token", accessToken)
		config.Write("spotify.refresh_token", refreshToken)
	}

	trackID, trackName, trackArtist := currentTrackInfo(accessToken)

	if trackID == "" {
		log.Error("No current track playing")
		os.Exit(1)
	}

	if isTrackSaved(accessToken, trackID) {
		log.Info("+\n%s\n%s", trackName, trackArtist)
		removeTrack(accessToken, trackID)
	} else {
		log.Info("-\n%s\n%s", trackName, trackArtist)
		saveTrack(accessToken, trackID)
	}
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
