// Requires creation of a Spotify API application here:
//   https://developer.spotify.com/dashboard/applications
//   Redirect URI: https://console.drn.dev/
// The following ENV variables must exist:
//   SPOTIFY_CLIENT_ID
//   SPOTIFY_CLIENT_SECRET

// This package provides a Spotify CLI to toggle, save, and remove the current
// song
package main

import (
	"fmt"
	"os"

	"github.com/drn/dots/cmd/spotify/auth"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
	"github.com/imroc/req"
	"github.com/joho/godotenv"
	jsoniter "github.com/json-iterator/go"
)

func main() {
	godotenv.Load(path.FromHome(".dots/env"))

	action := "toggle"
	if len(os.Args) >= 2 {
		if os.Args[1] == "save" || os.Args[1] == "remove" || os.Args[1] == "transfer" {
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
	case "transfer":
		currentDeviceID := currentDevice(accessToken)
		transferPlayback(accessToken, alternateDeviceID(currentDeviceID))
	}
}

func alternateDeviceID(currentDeviceID string) string {
	// if laptop, transfer to iphone
	if currentDeviceID == "ffac8fe2389bf5536633fec4320117105a77d45f" {
		return "010a8a7f027d31cd55b229dd11a8f4f3e32cc9e5"
	}
	// default to laptop
	return "ffac8fe2389bf5536633fec4320117105a77d45f"
}

func currentDevice(accessToken string) string {
	url := "https://api.spotify.com/v1/me/player/devices"

	response, err := req.Get(url, headers(accessToken))
	handleRequestError(err)

	i := 0
	for i < 10 {
		id := jsoniter.Get(response.Bytes(), "devices", i, "id").ToString()
		isActive := jsoniter.Get(response.Bytes(), "devices", i, "is_active").ToBool()
		if isActive {
			return id
		}
		i++
	}
	return ""
}

func transferPlayback(accessToken string, deviceID string) {
	url := "https://api.spotify.com/v1/me/player"
	json := req.BodyJSON(map[string]interface{}{"device_ids": []string{deviceID}})
	response, err := req.Put(url, headers(accessToken), json)
	handleRequestError(err)
	if response.Response().StatusCode != 204 {
		println(response.Dump())
		log.Error("Failed to transfer device")
		os.Exit(1)
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
