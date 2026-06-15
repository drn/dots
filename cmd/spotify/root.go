// Requires creation of a Spotify API application here:
//   https://developer.spotify.com/dashboard/applications
// The following ENV variables must exist:
//   SPOTIFY_CLIENT_ID
//   SPOTIFY_CLIENT_SECRET
//   SPOTIFY_REDIRECT_URI - a loopback URL with an explicit port, e.g.
//     http://127.0.0.1:8888/callback. The CLI starts a local server on that
//     port to capture the OAuth callback, so the same URL must be registered
//     as a redirect URI on the Spotify app.

// This package provides a Spotify CLI to toggle, save, and remove the current
// song
package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/url"
	"os"

	"github.com/drn/dots/cmd/spotify/auth"
	"github.com/drn/dots/pkg/log"
	"github.com/drn/dots/pkg/path"
	"github.com/joho/godotenv"
	jsoniter "github.com/json-iterator/go"
)

const (
	spotifyTracksURL   = "https://api.spotify.com/v1/me/tracks"
	spotifyPlayerURL   = "https://api.spotify.com/v1/me/player"
	spotifyDevicesURL  = "https://api.spotify.com/v1/me/player/devices"
	spotifyNowPlaying  = "https://api.spotify.com/v1/me/player/currently-playing"
	spotifyContainsURL = "https://api.spotify.com/v1/me/tracks/contains"
)

func main() {
	godotenv.Load(path.FromHome(".dots/sys/env"))

	action := "toggle"
	if len(os.Args) >= 2 {
		switch os.Args[1] {
		case "save", "remove", "transfer":
			action = os.Args[1]
		default:
			log.Error("Usage: spotify [save|remove|transfer]?")
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
	laptopID := os.Getenv("SPOTIFY_DEVICE_LAPTOP")
	phoneID := os.Getenv("SPOTIFY_DEVICE_PHONE")
	// if laptop, transfer to phone
	if currentDeviceID == laptopID {
		return phoneID
	}
	// default to laptop
	return laptopID
}

func currentDevice(accessToken string) string {
	data, status := auth.SendRequest(
		http.MethodGet, spotifyDevicesURL, auth.Headers(accessToken), nil, nil,
	)
	if status >= http.StatusBadRequest {
		log.Error("Failed to list devices (status %d)", status)
		os.Exit(1)
	}

	const maxDevices = 10
	for i := 0; i < maxDevices; i++ {
		id := jsoniter.Get(data, "devices", i, "id").ToString()
		if id == "" {
			break
		}
		if jsoniter.Get(data, "devices", i, "is_active").ToBool() {
			return id
		}
	}
	return ""
}

func transferPlayback(accessToken string, deviceID string) {
	body, err := json.Marshal(map[string]interface{}{"device_ids": []string{deviceID}})
	auth.HandleRequestError(err)
	data, status := auth.SendRequest(
		http.MethodPut, spotifyPlayerURL, auth.Headers(accessToken), nil, bytes.NewReader(body),
	)
	if status != http.StatusNoContent {
		println(string(data))
		log.Error("Failed to transfer device")
		os.Exit(1)
	}
}

// https://developer.spotify.com/documentation/web-api/reference/library/save-tracks-user/
func saveTrack(accessToken string, trackID string) {
	params := url.Values{"ids": {trackID}}
	_, status := auth.SendRequest(
		http.MethodPut, spotifyTracksURL, auth.Headers(accessToken), params, nil,
	)
	if status != http.StatusOK {
		log.Error("Failed to save track")
		os.Exit(1)
	}
}

// https://developer.spotify.com/documentation/web-api/reference/library/remove-tracks-user/
func removeTrack(accessToken string, trackID string) {
	params := url.Values{"ids": {trackID}}
	_, status := auth.SendRequest(
		http.MethodDelete, spotifyTracksURL, auth.Headers(accessToken), params, nil,
	)
	if status != http.StatusOK {
		log.Error("Failed to remove track")
		os.Exit(1)
	}
}

// https://developer.spotify.com/documentation/web-api/reference/library/check-users-saved-tracks/
func isTrackSaved(accessToken string, trackID string) bool {
	params := url.Values{"ids": {trackID}}
	data, status := auth.SendRequest(
		http.MethodGet, spotifyContainsURL, auth.Headers(accessToken), params, nil,
	)
	if status >= http.StatusBadRequest {
		log.Error("Failed to check saved status (status %d)", status)
		os.Exit(1)
	}
	return jsoniter.Get(data, 0).ToBool()
}

// https://developer.spotify.com/documentation/web-api/reference/player/get-the-users-currently-playing-track/
func currentTrackInfo(accessToken string) (string, string, string) {
	data, status := auth.SendRequest(
		http.MethodGet, spotifyNowPlaying, auth.Headers(accessToken), nil, nil,
	)
	// Spotify returns 204 No Content when nothing is playing — treat that
	// as "no current track" via the empty id below. Surface 4xx/5xx instead
	// of silently parsing an error body.
	if status >= http.StatusBadRequest {
		log.Error("Failed to fetch currently-playing track (status %d)", status)
		os.Exit(1)
	}
	id := jsoniter.Get(data, "item", "id").ToString()
	name := jsoniter.Get(data, "item", "name").ToString()
	artist := jsoniter.Get(data, "item", "artists", 0, "name").ToString()

	return id, name, artist
}
