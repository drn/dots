// Requires creation of a Spotify API application here:
//   https://developer.spotify.com/dashboard/applications
//   Redirect URI: https://console.drn.dev/
// The following ENV variables must exist:
//   SPOTIFY_CLIENT_ID
//   SPOTIFY_CLIENT_SECRET

package main

import (
	"fmt"
	"os"

	"github.com/drn/dots/cli/log"
	"github.com/drn/dots/cli/path"
	"github.com/drn/dots/cmd/spotify/auth"
	"github.com/imroc/req"
	"github.com/joho/godotenv"
	jsoniter "github.com/json-iterator/go"
)

func main() {
	godotenv.Load(path.FromHome(".dots/env"))

	action := "toggle"
	if len(os.Args) >= 2 {
		if os.Args[1] == "save" || os.Args[1] == "remove" {
			action = os.Args[1]
		} else {
			log.Error("Usage: spotify [save|remove]?")
			os.Exit(1)
		}
	}

	accessToken := auth.FetchAccessToken()

	trackID, trackName, trackArtist := currentTrackInfo(accessToken)

	if trackID == "" {
		log.Error("No current track playing")
		os.Exit(1)
	}

	switch action {
	case "toggle":
		if isTrackSaved(accessToken, trackID) {
			log.Info("[−]\n%s\n%s", trackName, trackArtist)
			removeTrack(accessToken, trackID)
		} else {
			log.Info("[+]\n%s\n%s", trackName, trackArtist)
			saveTrack(accessToken, trackID)
		}
	case "save":
		if !isTrackSaved(accessToken, trackID) {
			log.Info("[+]\n%s\n%s", trackName, trackArtist)
			saveTrack(accessToken, trackID)
		} else {
			log.Info("(+)\n%s\n%s", trackName, trackArtist)
		}
	case "remove":
		if isTrackSaved(accessToken, trackID) {
			log.Info("[−]\n%s\n%s", trackName, trackArtist)
			removeTrack(accessToken, trackID)
		} else {
			log.Info("(-)\n%s\n%s", trackName, trackArtist)
		}
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
