// Usage: tts [flags] TEXT
// Speaks text aloud using OpenAI's TTS API and macOS afplay.
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"strings"

	"github.com/drn/dots/pkg/path"
	"github.com/joho/godotenv"
	"github.com/spf13/cobra"
)

// apiURL is the OpenAI TTS endpoint, overridable for testing.
var apiURL = "https://api.openai.com/v1/audio/speech"

// playCmd is the command used to play audio, overridable for testing.
var playCmd = "afplay"

func init() {
	godotenv.Load(path.FromDots("sys/env"))
}

func apiKey() string {
	if k := os.Getenv("OPENAI_API_KEY"); k != "" {
		return k
	}
	fmt.Fprintln(os.Stderr, "OPENAI_API_KEY not set")
	os.Exit(1)
	return ""
}

func main() {
	var voice string
	var speed float64
	var model string

	root := &cobra.Command{
		Use:   "tts TEXT",
		Short: "Speak text aloud using OpenAI TTS",
		Args:  cobra.MinimumNArgs(1),
		Run: func(_ *cobra.Command, args []string) {
			text := strings.Join(args, " ")
			if err := speak(text, voice, speed, model); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
		},
	}

	root.Flags().StringVarP(&voice, "voice", "v", "alloy", "Voice (alloy, echo, fable, onyx, nova, shimmer)")
	root.Flags().Float64VarP(&speed, "speed", "s", 1.0, "Speed (0.25-4.0)")
	root.Flags().StringVarP(&model, "model", "m", "tts-1", "Model (tts-1, tts-1-hd)")

	root.Execute()
}

// buildRequest constructs the OpenAI TTS API request.
func buildRequest(text, voice, model string, speed float64) (*http.Request, error) {
	body, err := json.Marshal(map[string]interface{}{
		"model":           model,
		"input":           text,
		"voice":           voice,
		"speed":           speed,
		"response_format": "mp3",
	})
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequest("POST", apiURL, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+apiKey())
	req.Header.Set("Content-Type", "application/json")
	return req, nil
}

func speak(text, voice string, speed float64, model string) error {
	if micActive() {
		return nil
	}

	req, err := buildRequest(text, voice, model, speed)
	if err != nil {
		return err
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		errBody, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("OpenAI API error (%d): %s", resp.StatusCode, string(errBody))
	}

	// Write to temp file and play with afplay
	tmp, err := os.CreateTemp("", "tts-*.mp3")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())

	if _, err := io.Copy(tmp, resp.Body); err != nil {
		tmp.Close()
		return err
	}
	tmp.Close()

	cmd := exec.Command(playCmd, tmp.Name())
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
