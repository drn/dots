// Usage: gmail <subcommand> [flags]
// Read-only Gmail API client for searching and reading emails.
package main

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/drn/dots/pkg/jsonutil"
	"github.com/drn/dots/pkg/path"
	"github.com/joho/godotenv"
	"github.com/spf13/cobra"
)

const gmailBase = "https://gmail.googleapis.com"

func init() {
	godotenv.Load(path.FromHome(".dots/sys/env"))
}

var configDir = path.FromHome(".dots/sys/gmail")
var debugMode bool

type tokenData struct {
	Email        string `json:"email"`
	Token        string `json:"token"`
	RefreshToken string `json:"refresh_token"`
	TokenURI     string `json:"token_uri"`
	ClientID     string `json:"client_id"`
	ClientSecret string `json:"client_secret"`
	Expiry       string `json:"expiry"`
}

func resolveAccount(account string) string {
	if account != "" {
		return account
	}
	accountsFile := filepath.Join(configDir, "accounts.json")
	data, err := os.ReadFile(accountsFile)
	if err == nil {
		var accounts map[string]interface{}
		if json.Unmarshal(data, &accounts) == nil {
			if def, ok := accounts["default"].(string); ok && def != "" {
				return def
			}
		}
	}
	tokensDir := filepath.Join(configDir, "tokens")
	entries, err := os.ReadDir(tokensDir)
	if err == nil {
		for _, e := range entries {
			if strings.HasSuffix(e.Name(), ".json") {
				return strings.TrimSuffix(e.Name(), ".json")
			}
		}
	}
	fmt.Fprintln(os.Stderr, "No Google accounts configured in ~/.dots/sys/gmail/tokens/")
	os.Exit(1)
	return ""
}

func loadToken(account string) *tokenData {
	account = resolveAccount(account)
	path := filepath.Join(configDir, "tokens", account+".json")
	data, err := os.ReadFile(path)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Token not found for account '%s': %v\n", account, err)
		os.Exit(1)
	}
	var td tokenData
	if err := json.Unmarshal(data, &td); err != nil {
		fmt.Fprintf(os.Stderr, "Invalid token file: %v\n", err)
		os.Exit(1)
	}
	return &td
}

func (td *tokenData) tokenValid() bool {
	if td.Expiry == "" {
		return false
	}
	exp, err := time.Parse(time.RFC3339, td.Expiry)
	if err != nil {
		if debugMode {
			fmt.Fprintf(os.Stderr, "debug: failed to parse expiry %q: %v\n", td.Expiry, err)
		}
		return false
	}
	return time.Now().Before(exp)
}

func (td *tokenData) refreshIfNeeded(account string) {
	if td.Expiry != "" {
		exp, err := time.Parse(time.RFC3339, td.Expiry)
		if debugMode {
			fmt.Fprintf(os.Stderr, "debug: expiry=%q parseErr=%v now=%s exp=%s\n",
				td.Expiry, err, time.Now().Format(time.RFC3339), exp.Format(time.RFC3339))
		}
		if err == nil && time.Now().Add(60*time.Second).Before(exp) {
			if debugMode {
				fmt.Fprintln(os.Stderr, "debug: token still valid, skipping refresh")
			}
			return
		}
		if debugMode {
			fmt.Fprintln(os.Stderr, "debug: token expired or expiring soon, attempting refresh")
		}
	}
	if td.RefreshToken == "" {
		if debugMode {
			fmt.Fprintln(os.Stderr, "debug: no refresh token, skipping refresh")
		}
		return
	}
	resp, err := http.PostForm(td.TokenURI, url.Values{
		"grant_type":    {"refresh_token"},
		"refresh_token": {td.RefreshToken},
		"client_id":     {td.ClientID},
		"client_secret": {td.ClientSecret},
	})
	if err != nil {
		if td.tokenValid() {
			fmt.Fprintf(os.Stderr, "Warning: token refresh failed, using existing access token\n")
			return
		}
		fmt.Fprintf(os.Stderr, "Token refresh failed: %v\n", err)
		os.Exit(1)
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != 200 {
		if td.tokenValid() {
			fmt.Fprintf(os.Stderr, "Warning: token refresh failed, using existing access token\n")
			if debugMode {
				fmt.Fprintf(os.Stderr, "debug: refresh response: %s\n", body)
			}
			return
		}
		fmt.Fprintf(os.Stderr, "Token refresh failed: %s\n", body)
		os.Exit(1)
	}
	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		fmt.Fprintf(os.Stderr, "Warning: failed to parse refresh response: %v\n", err)
		return
	}
	if at, ok := result["access_token"].(string); ok {
		td.Token = at
	}
	if ei, ok := result["expires_in"].(float64); ok {
		td.Expiry = time.Now().Add(time.Duration(ei) * time.Second).Format(time.RFC3339)
	}
	account = resolveAccount(account)
	tokenPath := filepath.Join(configDir, "tokens", account+".json")
	data, err := json.MarshalIndent(td, "", "  ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Warning: failed to marshal token: %v\n", err)
		return
	}
	if err := os.WriteFile(tokenPath, data, 0600); err != nil {
		fmt.Fprintf(os.Stderr, "Warning: failed to save token: %v\n", err)
	}
}

func getAccessToken(account string) string {
	td := loadToken(account)
	td.refreshIfNeeded(account)
	return td.Token
}

func gmailGet(accessToken, urlStr string) (map[string]interface{}, error) {
	req, err := http.NewRequest("GET", urlStr, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode == 401 {
		return nil, fmt.Errorf("unauthorized: token expired or invalid")
	}
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("HTTP %d: %s", resp.StatusCode, string(body[:min(len(body), 200)]))
	}
	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}
	return result, nil
}

func decodeBase64URL(s string) string {
	data, err := base64.URLEncoding.WithPadding(base64.NoPadding).DecodeString(s)
	if err != nil {
		return ""
	}
	return string(data)
}

func getHeader(payload map[string]interface{}, name string) string {
	headers, _ := payload["headers"].([]interface{})
	for _, h := range headers {
		hm, _ := h.(map[string]interface{})
		n, _ := hm["name"].(string)
		if strings.EqualFold(n, name) {
			v, _ := hm["value"].(string)
			return v
		}
	}
	return ""
}

func extractBody(payload map[string]interface{}) (string, string) {
	var textBody, htmlBody string
	mimeType, _ := payload["mimeType"].(string)

	if body, ok := payload["body"].(map[string]interface{}); ok {
		if data, ok := body["data"].(string); ok && data != "" {
			decoded := decodeBase64URL(data)
			if strings.Contains(mimeType, "text/plain") {
				textBody += decoded
			} else if strings.Contains(mimeType, "text/html") {
				htmlBody += decoded
			}
		}
	}

	parts, _ := payload["parts"].([]interface{})
	for _, part := range parts {
		pm, _ := part.(map[string]interface{})
		partMime, _ := pm["mimeType"].(string)
		if body, ok := pm["body"].(map[string]interface{}); ok {
			if data, _ := body["data"].(string); data != "" {
				decoded := decodeBase64URL(data)
				if strings.Contains(partMime, "text/plain") {
					textBody += decoded
				} else if strings.Contains(partMime, "text/html") {
					htmlBody += decoded
				}
			}
		}
		if nested, ok := pm["parts"].([]interface{}); ok && len(nested) > 0 {
			nt, nh := extractBody(pm)
			textBody += nt
			htmlBody += nh
		}
	}
	return textBody, htmlBody
}

func openBrowser(url string) {
	switch runtime.GOOS {
	case "darwin":
		exec.Command("open", url).Start()
	case "linux":
		exec.Command("xdg-open", url).Start()
	default:
		fmt.Printf("Open this URL in your browser:\n%s\n", url)
	}
}


func main() {
	var jsonFlag bool
	var limitFlag int
	var accountFlag string

	root := &cobra.Command{
		Use:   "gmail",
		Short: "Read-only Gmail API client",
	}

	searchCmd := &cobra.Command{
		Use:   "search QUERY",
		Short: "Search Gmail messages",
		Args:  cobra.ExactArgs(1),
		Run: func(_ *cobra.Command, args []string) {
			token := getAccessToken(accountFlag)
			u := fmt.Sprintf("%s/gmail/v1/users/me/messages?q=%s&maxResults=%d",
				gmailBase, url.QueryEscape(args[0]), limitFlag)
			data, err := gmailGet(token, u)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
			messages, _ := data["messages"].([]interface{})

			type msgMeta struct {
				ID      string `json:"id"`
				From    string `json:"from"`
				To      string `json:"to"`
				Subject string `json:"subject"`
				Date    string `json:"date"`
				Snippet string `json:"snippet"`
			}
			var results []msgMeta

			for _, msg := range messages {
				mm, _ := msg.(map[string]interface{})
				id, _ := mm["id"].(string)
				metaURL := fmt.Sprintf("%s/gmail/v1/users/me/messages/%s?format=metadata"+
					"&metadataHeaders=From&metadataHeaders=To&metadataHeaders=Subject&metadataHeaders=Date",
					gmailBase, id)
				full, err := gmailGet(token, metaURL)
				if err != nil {
					results = append(results, msgMeta{ID: id})
					continue
				}
				payload, _ := full["payload"].(map[string]interface{})
				snippet, _ := full["snippet"].(string)
				results = append(results, msgMeta{
					ID:      id,
					From:    getHeader(payload, "From"),
					To:      getHeader(payload, "To"),
					Subject: getHeader(payload, "Subject"),
					Date:    getHeader(payload, "Date"),
					Snippet: snippet,
				})
			}

			if jsonFlag {
				jsonutil.Print(results)
				return
			}
			if len(results) == 0 {
				fmt.Println("No messages found.")
				return
			}
			fmt.Printf("Found %d messages:\n\n", len(results))
			for _, r := range results {
				from := r.From
				if len(from) > 40 {
					from = from[:40]
				}
				subject := r.Subject
				if len(subject) > 50 {
					subject = subject[:50]
				}
				fmt.Printf("[%s] %s\n  From: %s\n  Subject: %s\n\n", r.Date, r.ID, from, subject)
			}
		},
	}
	searchCmd.Flags().IntVarP(&limitFlag, "limit", "l", 20, "Max results")
	searchCmd.Flags().StringVarP(&accountFlag, "account", "a", "", "Account name")
	searchCmd.Flags().BoolVar(&jsonFlag, "json", false, "JSON output")

	readCmd := &cobra.Command{
		Use:   "read MESSAGE_ID",
		Short: "Read a Gmail message",
		Args:  cobra.ExactArgs(1),
		Run: func(_ *cobra.Command, args []string) {
			token := getAccessToken(accountFlag)
			u := fmt.Sprintf("%s/gmail/v1/users/me/messages/%s?format=full", gmailBase, args[0])
			data, err := gmailGet(token, u)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
			payload, _ := data["payload"].(map[string]interface{})
			from := getHeader(payload, "From")
			to := getHeader(payload, "To")
			subject := getHeader(payload, "Subject")
			date := getHeader(payload, "Date")

			textBody, htmlBody := extractBody(payload)

			if jsonFlag {
				jsonutil.Print(map[string]interface{}{
					"id":        data["id"],
					"from":      from,
					"to":        to,
					"subject":   subject,
					"date":      date,
					"body_text": textBody,
					"body_html": htmlBody,
					"labels":    data["labelIds"],
				})
				return
			}

			fmt.Printf("From: %s\n", from)
			fmt.Printf("To: %s\n", to)
			fmt.Printf("Subject: %s\n", subject)
			fmt.Printf("Date: %s\n", date)
			labels, _ := data["labelIds"].([]interface{})
			labelStrs := make([]string, 0, len(labels))
			for _, l := range labels {
				if s, ok := l.(string); ok {
					labelStrs = append(labelStrs, s)
				}
			}
			fmt.Printf("Labels: %s\n", strings.Join(labelStrs, ", "))
			fmt.Printf("\n%s\n", strings.Repeat("=", 60))

			body := textBody
			if body == "" {
				body = htmlBody
			}
			if body == "" {
				body = "(no body)"
			}
			if len(body) > 5000 {
				body = body[:5000] + "\n\n... (truncated)"
			}
			fmt.Println(body)
		},
	}
	readCmd.Flags().StringVarP(&accountFlag, "account", "a", "", "Account name")
	readCmd.Flags().BoolVar(&jsonFlag, "json", false, "JSON output")

	labelsCmd := &cobra.Command{
		Use:   "labels",
		Short: "List Gmail labels",
		Run: func(_ *cobra.Command, _ []string) {
			token := getAccessToken(accountFlag)
			u := fmt.Sprintf("%s/gmail/v1/users/me/labels", gmailBase)
			data, err := gmailGet(token, u)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
			labels, _ := data["labels"].([]interface{})

			type labelInfo struct {
				ID       string `json:"id"`
				Name     string `json:"name"`
				Type     string `json:"type"`
				Total    int    `json:"messages_total"`
				Unread   int    `json:"messages_unread"`
			}
			var results []labelInfo

			for _, l := range labels {
				lm, _ := l.(map[string]interface{})
				id, _ := lm["id"].(string)
				detailURL := fmt.Sprintf("%s/gmail/v1/users/me/labels/%s", gmailBase, id)
				detail, err := gmailGet(token, detailURL)
				if err != nil {
					name, _ := lm["name"].(string)
					results = append(results, labelInfo{ID: id, Name: name})
					continue
				}
				name, _ := detail["name"].(string)
				ltype, _ := detail["type"].(string)
				total, _ := detail["messagesTotal"].(float64)
				unread, _ := detail["messagesUnread"].(float64)
				results = append(results, labelInfo{
					ID: id, Name: name, Type: ltype,
					Total: int(total), Unread: int(unread),
				})
			}

			if jsonFlag {
				jsonutil.Print(results)
				return
			}

			fmt.Print("Gmail Labels:\n\n")
			var system, user []labelInfo
			for _, r := range results {
				if r.Type == "system" {
					system = append(system, r)
				} else {
					user = append(user, r)
				}
			}
			if len(system) > 0 {
				fmt.Println("System Labels:")
				for _, l := range system {
					unread := ""
					if l.Unread > 0 {
						unread = fmt.Sprintf(" (%d unread)", l.Unread)
					}
					fmt.Printf("  %-20s %5d messages%s\n", l.Name, l.Total, unread)
				}
			}
			if len(user) > 0 {
				fmt.Println("\nUser Labels:")
				for _, l := range user {
					unread := ""
					if l.Unread > 0 {
						unread = fmt.Sprintf(" (%d unread)", l.Unread)
					}
					fmt.Printf("  %-20s %5d messages%s\n", l.Name, l.Total, unread)
				}
			}
		},
	}
	labelsCmd.Flags().StringVarP(&accountFlag, "account", "a", "", "Account name")
	labelsCmd.Flags().BoolVar(&jsonFlag, "json", false, "JSON output")

	accountsCmd := &cobra.Command{
		Use:   "accounts",
		Short: "List configured Gmail accounts",
		Run: func(_ *cobra.Command, _ []string) {
			accountsFile := filepath.Join(configDir, "accounts.json")
			var defaultAccount string
			if data, err := os.ReadFile(accountsFile); err == nil {
				var accts map[string]interface{}
				if json.Unmarshal(data, &accts) == nil {
					defaultAccount, _ = accts["default"].(string)
				}
			}

			tokensDir := filepath.Join(configDir, "tokens")
			entries, err := os.ReadDir(tokensDir)
			if err != nil {
				fmt.Fprintln(os.Stderr, "No accounts configured in ~/.dots/sys/gmail/tokens/")
				os.Exit(1)
			}

			type acctInfo struct {
				Name    string `json:"name"`
				Email   string `json:"email"`
				Default bool   `json:"default"`
			}
			var accounts []acctInfo
			for _, e := range entries {
				if !strings.HasSuffix(e.Name(), ".json") {
					continue
				}
				name := strings.TrimSuffix(e.Name(), ".json")
				var email string
				if data, err := os.ReadFile(filepath.Join(tokensDir, e.Name())); err == nil {
					var td tokenData
					if json.Unmarshal(data, &td) == nil {
						email = td.Email
					}
				}
				accounts = append(accounts, acctInfo{
					Name:    name,
					Email:   email,
					Default: name == defaultAccount,
				})
			}

			if jsonFlag {
				jsonutil.Print(accounts)
				return
			}
			for _, a := range accounts {
				marker := "  "
				if a.Default {
					marker = "* "
				}
				fmt.Printf("%s%-12s %s\n", marker, a.Name, a.Email)
			}
		},
	}
	accountsCmd.Flags().BoolVar(&jsonFlag, "json", false, "JSON output")

	authCmd := &cobra.Command{
		Use:   "auth ACCOUNT",
		Short: "Authenticate or re-authenticate a Gmail account",
		Args:  cobra.ExactArgs(1),
		Run: func(_ *cobra.Command, args []string) {
			account := args[0]
			tokenPath := filepath.Join(configDir, "tokens", account+".json")

			// Load existing token to reuse client credentials
			var td tokenData
			if data, err := os.ReadFile(tokenPath); err == nil {
				json.Unmarshal(data, &td)
			}
			if td.ClientID == "" || td.ClientSecret == "" {
				fmt.Fprintln(os.Stderr, "No existing token with client credentials found.")
				fmt.Fprintf(os.Stderr, "Create %s with client_id and client_secret first.\n", tokenPath)
				os.Exit(1)
			}
			if td.TokenURI == "" {
				td.TokenURI = "https://oauth2.googleapis.com/token"
			}

			// Find a free port for the callback
			listener, err := net.Listen("tcp", "localhost:0")
			if err != nil {
				fmt.Fprintf(os.Stderr, "Failed to open listener: %v\n", err)
				os.Exit(1)
			}
			port := listener.Addr().(*net.TCPAddr).Port
			redirectURI := fmt.Sprintf("http://localhost:%d/callback", port)

			// Build the OAuth URL
			authURL := fmt.Sprintf(
				"https://accounts.google.com/o/oauth2/v2/auth?client_id=%s&redirect_uri=%s&response_type=code&scope=%s&access_type=offline&prompt=consent",
				url.QueryEscape(td.ClientID),
				url.QueryEscape(redirectURI),
				url.QueryEscape("https://www.googleapis.com/auth/gmail.readonly"),
			)

			codeCh := make(chan string, 1)
			errCh := make(chan error, 1)

			mux := http.NewServeMux()
			mux.HandleFunc("/callback", func(w http.ResponseWriter, r *http.Request) {
				code := r.URL.Query().Get("code")
				if code == "" {
					errMsg := r.URL.Query().Get("error")
					fmt.Fprintf(w, "Authorization failed: %s", errMsg)
					errCh <- fmt.Errorf("authorization failed: %s", errMsg)
					return
				}
				fmt.Fprint(w, "Authorization successful! You can close this tab.")
				codeCh <- code
			})

			srv := &http.Server{Handler: mux}
			go srv.Serve(listener)

			fmt.Printf("Opening browser for %s account authorization...\n", account)
			openBrowser(authURL)
			fmt.Println("Waiting for authorization...")

			var code string
			select {
			case code = <-codeCh:
			case err := <-errCh:
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			case <-time.After(2 * time.Minute):
				fmt.Fprintln(os.Stderr, "Timed out waiting for authorization")
				os.Exit(1)
			}
			srv.Shutdown(context.Background())

			// Exchange code for tokens
			resp, err := http.PostForm(td.TokenURI, url.Values{
				"grant_type":    {"authorization_code"},
				"code":          {code},
				"redirect_uri":  {redirectURI},
				"client_id":     {td.ClientID},
				"client_secret": {td.ClientSecret},
			})
			if err != nil {
				fmt.Fprintf(os.Stderr, "Token exchange failed: %v\n", err)
				os.Exit(1)
			}
			defer resp.Body.Close()
			body, _ := io.ReadAll(resp.Body)
			if resp.StatusCode != 200 {
				fmt.Fprintf(os.Stderr, "Token exchange failed: %s\n", body)
				os.Exit(1)
			}

			var result map[string]interface{}
			if err := json.Unmarshal(body, &result); err != nil {
				fmt.Fprintf(os.Stderr, "Failed to parse token response: %v\n", err)
				os.Exit(1)
			}
			if at, ok := result["access_token"].(string); ok {
				td.Token = at
			}
			if rt, ok := result["refresh_token"].(string); ok {
				td.RefreshToken = rt
			}
			if ei, ok := result["expires_in"].(float64); ok {
				td.Expiry = time.Now().Add(time.Duration(ei) * time.Second).Format(time.RFC3339)
			}

			// Fetch email address from profile
			profileURL := fmt.Sprintf("%s/gmail/v1/users/me/profile", gmailBase)
			if profile, err := gmailGet(td.Token, profileURL); err == nil {
				if email, ok := profile["emailAddress"].(string); ok {
					td.Email = email
				}
			}

			if err := os.MkdirAll(filepath.Join(configDir, "tokens"), 0700); err != nil {
				fmt.Fprintf(os.Stderr, "Failed to create tokens directory: %v\n", err)
				os.Exit(1)
			}
			data, _ := json.MarshalIndent(td, "", "  ")
			if err := os.WriteFile(tokenPath, data, 0600); err != nil {
				fmt.Fprintf(os.Stderr, "Failed to save token: %v\n", err)
				os.Exit(1)
			}
			fmt.Printf("Authenticated %s (%s)\n", account, td.Email)
		},
	}

	root.PersistentFlags().BoolVar(&debugMode, "debug", false, "Show debug output for token refresh")
	root.AddCommand(searchCmd, readCmd, labelsCmd, accountsCmd, authCmd)
	if err := root.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
