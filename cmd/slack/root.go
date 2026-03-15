// Usage: slack <subcommand> [flags]
// Read-only Slack API client for searching messages, listing channels/users,
// and reading history.
package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/drn/dots/pkg/jsonutil"
	"github.com/drn/dots/pkg/path"
	"github.com/joho/godotenv"
	"github.com/spf13/cobra"
)

const slackAPIBase = "https://slack.com/api"

func init() {
	godotenv.Load(path.FromHome(".dots/sys/env"))
}

func requiredEnv(name string) string {
	if t := os.Getenv(name); t != "" {
		return t
	}
	fmt.Fprintf(os.Stderr, "%s not set\n", name)
	os.Exit(1)
	return ""
}

func userToken() string { return requiredEnv("SLACK_XOXP_TOKEN") }
func botToken() string  { return requiredEnv("SLACK_XOXB_TOKEN") }

func slackGet(token, method string, params url.Values) (map[string]interface{}, error) {
	u := slackAPIBase + "/" + method
	if len(params) > 0 {
		u += "?" + params.Encode()
	}
	req, err := http.NewRequest("GET", u, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("invalid JSON: %w", err)
	}
	if ok, _ := result["ok"].(bool); !ok {
		errStr, _ := result["error"].(string)
		if errStr == "ratelimited" {
			ra := resp.Header.Get("Retry-After")
			return nil, fmt.Errorf("rate limited, retry after %ss", ra)
		}
		return nil, fmt.Errorf("slack API error: %s", errStr)
	}
	return result, nil
}

func paginate(token, method string, params url.Values, key string, limit int) ([]interface{}, error) {
	var results []interface{}
	cursor := ""
	for len(results) < limit {
		p := url.Values{}
		for k, v := range params {
			p[k] = v
		}
		pageSize := 200
		if limit-len(results) < pageSize {
			pageSize = limit - len(results)
		}
		p.Set("limit", strconv.Itoa(pageSize))
		if cursor != "" {
			p.Set("cursor", cursor)
		}
		data, err := slackGet(token, method, p)
		if err != nil {
			return results, err
		}
		if items, ok := data[key].([]interface{}); ok {
			results = append(results, items...)
		}
		meta, _ := data["response_metadata"].(map[string]interface{})
		nextCursor, _ := meta["next_cursor"].(string)
		if nextCursor == "" {
			break
		}
		cursor = nextCursor
	}
	if len(results) > limit {
		results = results[:limit]
	}
	return results, nil
}

func formatTS(ts string) string {
	f, err := strconv.ParseFloat(ts, 64)
	if err != nil {
		return ts
	}
	return time.Unix(int64(f), 0).Format("2006-01-02 15:04:05")
}

func daysAgoTS(days int) string {
	return fmt.Sprintf("%f", float64(time.Now().Add(-time.Duration(days)*24*time.Hour).Unix()))
}

func hoursAgoTS(hours int) string {
	return fmt.Sprintf("%f", float64(time.Now().Add(-time.Duration(hours)*time.Hour).Unix()))
}


func resolveChannelID(name string) string {
	if len(name) > 0 && (name[0] == 'C' || name[0] == 'G' || name[0] == 'D') {
		if _, err := strconv.Atoi(name[1:]); err != nil {
			// Could be a name starting with C/G/D — fall through to lookup
			// But Slack IDs are alphanumeric, so check length
			if len(name) >= 9 {
				return name
			}
		} else {
			return name
		}
	}
	clean := strings.ToLower(strings.TrimPrefix(name, "#"))
	params := url.Values{"types": {"public_channel,private_channel"}, "exclude_archived": {"true"}}
	channels, err := paginate(botToken(), "conversations.list", params, "channels", 1000)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error listing channels: %v\n", err)
		os.Exit(1)
	}
	for _, ch := range channels {
		m, _ := ch.(map[string]interface{})
		if n, _ := m["name"].(string); strings.ToLower(n) == clean {
			id, _ := m["id"].(string)
			return id
		}
	}
	fmt.Fprintf(os.Stderr, "Channel '%s' not found\n", name)
	os.Exit(1)
	return ""
}

func main() {
	var jsonFlag bool
	var limitFlag int
	var daysFlag int
	var hoursFlag int
	var sortFlag string
	var fullFlag bool

	root := &cobra.Command{
		Use:   "slack",
		Short: "Read-only Slack API client",
	}

	authTestCmd := &cobra.Command{
		Use:   "auth-test",
		Short: "Test Slack authentication",
		Run: func(_ *cobra.Command, _ []string) {
			data, err := slackGet(userToken(), "auth.test", nil)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
			if jsonFlag {
				jsonutil.Print(data)
				return
			}
			fmt.Println("Authentication successful!")
			fmt.Printf("  Team: %s (%s)\n", data["team"], data["team_id"])
			fmt.Printf("  User: %s (%s)\n", data["user"], data["user_id"])
			fmt.Printf("  URL:  %s\n", data["url"])
		},
	}
	authTestCmd.Flags().BoolVar(&jsonFlag, "json", false, "JSON output")

	channelsCmd := &cobra.Command{
		Use:   "channels",
		Short: "List channels",
		Run: func(_ *cobra.Command, _ []string) {
			params := url.Values{
				"types":            {"public_channel,private_channel"},
				"exclude_archived": {"true"},
			}
			channels, err := paginate(botToken(), "conversations.list", params, "channels", limitFlag)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
			if jsonFlag {
				jsonutil.Print(channels)
				return
			}
			fmt.Printf("Found %d channels:\n\n", len(channels))
			for _, ch := range channels {
				m, _ := ch.(map[string]interface{})
				name, _ := m["name"].(string)
				id, _ := m["id"].(string)
				members, _ := m["num_members"].(float64)
				purpose := ""
				if p, ok := m["purpose"].(map[string]interface{}); ok {
					purpose, _ = p["value"].(string)
				}
				if len(purpose) > 50 {
					purpose = purpose[:50]
				}
				priv := "        "
				if isPriv, _ := m["is_private"].(bool); isPriv {
					priv = "[private]"
				}
				fmt.Printf("%s #%-25s (%s) - %.0f members - %s\n", priv, name, id, members, purpose)
			}
		},
	}
	channelsCmd.Flags().IntVarP(&limitFlag, "limit", "l", 200, "Max channels")
	channelsCmd.Flags().BoolVar(&jsonFlag, "json", false, "JSON output")

	findChannelCmd := &cobra.Command{
		Use:   "find-channel NAME",
		Short: "Find a channel by name",
		Args:  cobra.ExactArgs(1),
		Run: func(_ *cobra.Command, args []string) {
			clean := strings.ToLower(strings.TrimPrefix(args[0], "#"))
			params := url.Values{"types": {"public_channel,private_channel"}, "exclude_archived": {"true"}}
			channels, err := paginate(botToken(), "conversations.list", params, "channels", 1000)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
			for _, ch := range channels {
				m, _ := ch.(map[string]interface{})
				if n, _ := m["name"].(string); strings.ToLower(n) == clean {
					if jsonFlag {
						jsonutil.Print(m)
						return
					}
					fmt.Printf("Found: #%s (%s)\n", m["name"], m["id"])
					return
				}
			}
			fmt.Fprintf(os.Stderr, "Channel '%s' not found\n", args[0])
			os.Exit(1)
		},
	}
	findChannelCmd.Flags().BoolVar(&jsonFlag, "json", false, "JSON output")

	historyCmd := &cobra.Command{
		Use:   "history CHANNEL",
		Short: "Fetch message history (by name or ID)",
		Args:  cobra.ExactArgs(1),
		Run: func(_ *cobra.Command, args []string) {
			channelID := resolveChannelID(args[0])
			params := url.Values{"channel": {channelID}}
			if daysFlag > 0 {
				params.Set("oldest", daysAgoTS(daysFlag))
			} else if hoursFlag > 0 {
				params.Set("oldest", hoursAgoTS(hoursFlag))
			}
			messages, err := paginate(userToken(), "conversations.history", params, "messages", limitFlag)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
			if jsonFlag {
				jsonutil.Print(messages)
				return
			}
			fmt.Printf("Last %d messages from %s:\n\n", len(messages), channelID)
			for i := len(messages) - 1; i >= 0; i-- {
				m, _ := messages[i].(map[string]interface{})
				ts, _ := m["ts"].(string)
				user, _ := m["user"].(string)
				text, _ := m["text"].(string)
				if len(text) > 200 {
					text = text[:200]
				}
				fmt.Printf("[%s] %s: %s\n", formatTS(ts), user, text)
				if rc, _ := m["reply_count"].(float64); rc > 0 {
					fmt.Printf("  └─ %.0f replies\n", rc)
				}
			}
		},
	}
	historyCmd.Flags().IntVarP(&limitFlag, "limit", "l", 100, "Max messages")
	historyCmd.Flags().IntVar(&daysFlag, "days", 0, "Only last N days")
	historyCmd.Flags().IntVar(&hoursFlag, "hours", 0, "Only last N hours")
	historyCmd.Flags().BoolVar(&jsonFlag, "json", false, "JSON output")

	threadCmd := &cobra.Command{
		Use:   "thread CHANNEL THREAD_TS",
		Short: "Fetch thread replies",
		Args:  cobra.ExactArgs(2),
		Run: func(_ *cobra.Command, args []string) {
			channelID := resolveChannelID(args[0])
			params := url.Values{"channel": {channelID}, "ts": {args[1]}}
			messages, err := paginate(userToken(), "conversations.replies", params, "messages", limitFlag)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
			if jsonFlag {
				jsonutil.Print(messages)
				return
			}
			fmt.Printf("Thread replies (%d):\n\n", len(messages))
			for _, msg := range messages {
				m, _ := msg.(map[string]interface{})
				ts, _ := m["ts"].(string)
				user, _ := m["user"].(string)
				text, _ := m["text"].(string)
				if len(text) > 200 {
					text = text[:200]
				}
				fmt.Printf("[%s] %s: %s\n", formatTS(ts), user, text)
			}
		},
	}
	threadCmd.Flags().IntVarP(&limitFlag, "limit", "l", 100, "Max replies")
	threadCmd.Flags().BoolVar(&jsonFlag, "json", false, "JSON output")

	searchCmd := &cobra.Command{
		Use:   "search QUERY",
		Short: "Search messages across Slack",
		Args:  cobra.ExactArgs(1),
		Run: func(_ *cobra.Command, args []string) {
			query := args[0]
			if daysFlag > 0 {
				after := time.Now().Add(-time.Duration(daysFlag) * 24 * time.Hour).Format("2006-01-02")
				query += " after:" + after
			}
			params := url.Values{
				"query": {query},
				"count": {strconv.Itoa(limitFlag)},
				"sort":  {sortFlag},
			}
			data, err := slackGet(userToken(), "search.messages", params)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
			msgs, _ := data["messages"].(map[string]interface{})
			matches, _ := msgs["matches"].([]interface{})
			if jsonFlag {
				jsonutil.Print(matches)
				return
			}
			fmt.Printf("Found %d messages matching '%s':\n\n", len(matches), query)
			for _, msg := range matches {
				m, _ := msg.(map[string]interface{})
				ts, _ := m["ts"].(string)
				user, _ := m["username"].(string)
				text, _ := m["text"].(string)
				channelName := "unknown"
				if ch, ok := m["channel"].(map[string]interface{}); ok {
					channelName, _ = ch["name"].(string)
				}
				if !fullFlag && len(text) > 200 {
					text = text[:200]
				}
				fmt.Printf("[%s] #%s | %s: %s\n\n", formatTS(ts), channelName, user, text)
			}
		},
	}
	searchCmd.Flags().IntVarP(&limitFlag, "limit", "l", 50, "Max results")
	searchCmd.Flags().IntVar(&daysFlag, "days", 0, "Restrict to last N days")
	searchCmd.Flags().StringVar(&sortFlag, "sort", "timestamp", "Sort order (timestamp or score)")
	searchCmd.Flags().BoolVarP(&fullFlag, "full", "f", false, "Show full message text")
	searchCmd.Flags().BoolVar(&jsonFlag, "json", false, "JSON output")

	usersCmd := &cobra.Command{
		Use:   "users",
		Short: "List workspace users",
		Run: func(_ *cobra.Command, _ []string) {
			users, err := paginate(botToken(), "users.list", url.Values{}, "members", limitFlag)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
			// Filter out bots and deleted
			var active []interface{}
			for _, u := range users {
				m, _ := u.(map[string]interface{})
				isBot, _ := m["is_bot"].(bool)
				deleted, _ := m["deleted"].(bool)
				if !isBot && !deleted {
					active = append(active, u)
				}
			}
			if jsonFlag {
				jsonutil.Print(active)
				return
			}
			fmt.Printf("Found %d users:\n\n", len(active))
			for _, u := range active {
				m, _ := u.(map[string]interface{})
				name, _ := m["name"].(string)
				id, _ := m["id"].(string)
				realName, _ := m["real_name"].(string)
				email := ""
				if p, ok := m["profile"].(map[string]interface{}); ok {
					email, _ = p["email"].(string)
				}
				fmt.Printf("@%-20s (%s) - %s - %s\n", name, id, realName, email)
			}
		},
	}
	usersCmd.Flags().IntVarP(&limitFlag, "limit", "l", 500, "Max users")
	usersCmd.Flags().BoolVar(&jsonFlag, "json", false, "JSON output")

	findUserCmd := &cobra.Command{
		Use:   "find-user NAME",
		Short: "Find a user by name",
		Args:  cobra.ExactArgs(1),
		Run: func(_ *cobra.Command, args []string) {
			search := strings.ToLower(args[0])
			users, err := paginate(botToken(), "users.list", url.Values{}, "members", 500)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
			for _, u := range users {
				m, _ := u.(map[string]interface{})
				if deleted, _ := m["deleted"].(bool); deleted {
					continue
				}
				name, _ := m["name"].(string)
				realName, _ := m["real_name"].(string)
				displayName := ""
				if p, ok := m["profile"].(map[string]interface{}); ok {
					displayName, _ = p["display_name"].(string)
				}
				if strings.Contains(strings.ToLower(name), search) ||
					strings.Contains(strings.ToLower(realName), search) ||
					strings.Contains(strings.ToLower(displayName), search) {
					if jsonFlag {
						jsonutil.Print(m)
						return
					}
					email := ""
					if p, ok := m["profile"].(map[string]interface{}); ok {
						email, _ = p["email"].(string)
					}
					fmt.Printf("Found: @%s (%s)\n", name, m["id"])
					fmt.Printf("  Real name:    %s\n", realName)
					fmt.Printf("  Display name: %s\n", displayName)
					fmt.Printf("  Email:        %s\n", email)
					return
				}
			}
			fmt.Fprintf(os.Stderr, "User '%s' not found\n", args[0])
			os.Exit(1)
		},
	}
	findUserCmd.Flags().BoolVar(&jsonFlag, "json", false, "JSON output")

	dmsCmd := &cobra.Command{
		Use:   "dms",
		Short: "List DM conversations",
		Run: func(_ *cobra.Command, _ []string) {
			var allDMs []interface{}
			for _, t := range []string{"im", "mpim"} {
				params := url.Values{"types": {t}, "exclude_archived": {"true"}}
				dms, err := paginate(userToken(), "conversations.list", params, "channels", limitFlag)
				if err != nil {
					if strings.Contains(err.Error(), "missing_scope") {
						continue
					}
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
				}
				allDMs = append(allDMs, dms...)
			}
			if jsonFlag {
				jsonutil.Print(allDMs)
				return
			}
			fmt.Printf("Found %d DM conversations:\n\n", len(allDMs))
			for _, dm := range allDMs {
				m, _ := dm.(map[string]interface{})
				id, _ := m["id"].(string)
				isMpim, _ := m["is_mpim"].(bool)
				dmType := "DM"
				if isMpim {
					dmType = "Group DM"
				}
				user, _ := m["user"].(string)
				if user == "" {
					user = "multiple users"
				}
				fmt.Printf("%s - %s with %s\n", id, dmType, user)
			}
		},
	}
	dmsCmd.Flags().IntVarP(&limitFlag, "limit", "l", 100, "Max DMs")
	dmsCmd.Flags().BoolVar(&jsonFlag, "json", false, "JSON output")

	root.AddCommand(authTestCmd, channelsCmd, findChannelCmd, historyCmd, threadCmd, searchCmd, usersCmd, findUserCmd, dmsCmd)
	if err := root.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
