// Usage: tts [flags] TEXT
// Speaks text aloud using Kokoro TTS (local) or OpenAI's TTS API (remote).
package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"syscall"
	"time"

	"github.com/drn/dots/pkg/path"
	"github.com/joho/godotenv"
	"github.com/spf13/cobra"
)

// apiURL is the OpenAI TTS endpoint, overridable for testing.
var apiURL = "https://api.openai.com/v1/audio/speech"

// playCmd is the command used to play audio, overridable for testing.
var playCmd = "afplay"

// lockPath is the file used for cross-process mutual exclusion of playback.
var lockPath = "/tmp/tts.lock"

// kokoroPython is the path to the Kokoro venv Python, overridable for testing.
var kokoroPython = filepath.Join(os.Getenv("HOME"), ".kokoro-tts", "bin", "python3")

// voiceMap maps OpenAI voice names to Kokoro voice IDs.
var voiceMap = map[string]string{
	"alloy":   "af_alloy",
	"echo":    "am_echo",
	"fable":   "bm_fable",
	"nova":    "af_nova",
	"onyx":    "am_onyx",
	"shimmer": "af_sky",
	"ash":     "am_adam",
	"coral":   "af_bella",
	"sage":    "am_michael",
}

// hfCacheDir is the HuggingFace cache directory for voice files, overridable for testing.
var hfCacheDir = filepath.Join(os.Getenv("HOME"), ".cache", "huggingface", "hub",
	"models--hexgrad--Kokoro-82M", "snapshots")

var validVoice = regexp.MustCompile(`^[a-z][a-z0-9_]*$`)

const defaultVoice = "af_heart"

// isVoiceCached checks if a Kokoro voice .pt file exists in the local HF cache.
func isVoiceCached(voice string) bool {
	if !validVoice.MatchString(voice) {
		return false
	}
	matches, err := filepath.Glob(filepath.Join(hfCacheDir, "*", "voices", voice+".pt"))
	return err == nil && len(matches) > 0
}

// ensureVoiceCached downloads a missing voice file and returns whether it is cached.
func ensureVoiceCached(voice string) bool {
	if isVoiceCached(voice) {
		return true
	}
	if !validVoice.MatchString(voice) {
		return false
	}
	// Download the missing voice file — pass voice as argv to avoid code injection
	script := "import sys; from huggingface_hub import hf_hub_download; hf_hub_download('hexgrad/Kokoro-82M', 'voices/' + sys.argv[1] + '.pt')"
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	cmd := exec.CommandContext(ctx, kokoroPython, "-c", script, voice)
	// Filter out existing HF_HUB_OFFLINE so the download can proceed
	var filtered []string
	for _, e := range os.Environ() {
		if !strings.HasPrefix(e, "HF_HUB_OFFLINE=") {
			filtered = append(filtered, e)
		}
	}
	cmd.Env = filtered
	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "warning: failed to cache voice %s: %v\n", voice, err)
	}
	// Re-check even on error — another process may have downloaded it concurrently
	return isVoiceCached(voice)
}

// resolveVoice maps a short name to a Kokoro voice ID.
func resolveVoice(name string) string {
	if strings.Contains(name, "_") {
		return name
	}
	if v, ok := voiceMap[name]; ok {
		return v
	}
	// Default to female American English voice prefix
	return "af_" + name
}

const kokoroScript = `import sys, warnings
warnings.filterwarnings('ignore')
import numpy as np, soundfile as sf
from kokoro import KPipeline
pipeline = KPipeline(lang_code='a')
chunks = [audio for _, _, audio in pipeline(sys.argv[1], voice=sys.argv[2], speed=float(sys.argv[3]))]
sf.write(sys.argv[4], np.concatenate(chunks), 24000)
`

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
	var remote bool

	root := &cobra.Command{
		Use:   "tts TEXT",
		Short: "Speak text aloud using Kokoro TTS (local) or OpenAI TTS (remote)",
		Args:  cobra.MinimumNArgs(1),
		Run: func(_ *cobra.Command, args []string) {
			text := strings.Join(args, " ")
			if !strings.HasSuffix(text, ".") && !strings.HasSuffix(text, "!") && !strings.HasSuffix(text, "?") {
				text += "."
			}
			var err error
			if remote {
				err = speakRemote(text, voice, speed, model)
			} else {
				err = speakLocal(text, resolveVoice(voice), speed)
			}
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
		},
	}

	root.Flags().StringVarP(&voice, "voice", "v", "heart", "Voice name (heart, alloy, nova, bella, sky, echo, onyx, ...)")
	root.Flags().Float64VarP(&speed, "speed", "s", 1.0, "Speed (0.25-4.0)")
	root.Flags().StringVarP(&model, "model", "m", "tts-1", "OpenAI model (tts-1, tts-1-hd) — only with --remote")
	root.Flags().BoolVar(&remote, "remote", false, "Use OpenAI API instead of local Kokoro")

	serveCmd := &cobra.Command{
		Use:   "serve",
		Short: "Start the Kokoro TTS daemon (keeps model warm for fast synthesis)",
		Args:  cobra.NoArgs,
		Run: func(_ *cobra.Command, _ []string) {
			if err := startDaemon(); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
		},
	}

	stopCmd := &cobra.Command{
		Use:   "stop",
		Short: "Stop the Kokoro TTS daemon",
		Args:  cobra.NoArgs,
		Run: func(_ *cobra.Command, _ []string) {
			if err := stopDaemon(); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
			fmt.Println("Daemon stopped.")
		},
	}

	cacheCmd := &cobra.Command{
		Use:   "cache VOICE [VOICE...]",
		Short: "Pre-download Kokoro voice files for offline use (e.g. alloy, af_alloy)",
		Args:  cobra.MinimumNArgs(1),
		Run: func(_ *cobra.Command, args []string) {
			failed := false
			for _, name := range args {
				resolved := resolveVoice(name)
				if !validVoice.MatchString(resolved) {
					fmt.Fprintf(os.Stderr, "%s: invalid voice name\n", name)
					failed = true
					continue
				}
				if isVoiceCached(resolved) {
					fmt.Printf("%s: already cached\n", resolved)
					continue
				}
				fmt.Printf("%s: downloading...\n", resolved)
				if ensureVoiceCached(resolved) {
					fmt.Printf("%s: cached\n", resolved)
				} else {
					fmt.Fprintf(os.Stderr, "%s: failed to cache\n", resolved)
					failed = true
				}
			}
			if failed {
				os.Exit(1)
			}
		},
	}

	root.AddCommand(serveCmd, stopCmd, cacheCmd)

	if err := root.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
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

func playWithLock(audioPath string) error {
	lf, err := os.OpenFile(lockPath, os.O_CREATE|os.O_RDWR, 0600)
	if err != nil {
		return err
	}
	defer lf.Close()
	if err := syscall.Flock(int(lf.Fd()), syscall.LOCK_EX); err != nil {
		return err
	}
	defer syscall.Flock(int(lf.Fd()), syscall.LOCK_UN)

	cmd := exec.Command(playCmd, audioPath)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func speakLocal(text, voice string, speed float64) error {
	if micActive() {
		return nil
	}

	cached := ensureVoiceCached(voice)
	if !cached {
		fmt.Fprintf(os.Stderr, "warning: voice %q not available, falling back to %s\n", voice, defaultVoice)
		voice = defaultVoice
		cached = ensureVoiceCached(voice)
	}

	tmp, err := os.CreateTemp("", "tts-*.wav")
	if err != nil {
		return err
	}
	tmp.Close()
	defer os.Remove(tmp.Name())

	// Try daemon first (warm model), fall back to cold start
	if err := speakViaDaemon(text, voice, speed, tmp.Name()); err != nil {
		// Start daemon in background so next invocation is fast
		startDaemonBackground()

		cmd := exec.Command(kokoroPython, "-c", kokoroScript, text, voice, fmt.Sprintf("%.2f", speed), tmp.Name())
		env := append(os.Environ(), "PYTORCH_ENABLE_MPS_FALLBACK=1")
		if cached {
			env = append(env, "HF_HUB_OFFLINE=1")
		}
		cmd.Env = env
		var stderr bytes.Buffer
		cmd.Stderr = &stderr
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("kokoro: %s: %w", strings.TrimSpace(stderr.String()), err)
		}
	}

	return playWithLock(tmp.Name())
}

func speakRemote(text, voice string, speed float64, model string) error {
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

	return playWithLock(tmp.Name())
}
