---
name: screenshot
description: >
  View recent screenshots from ~/Downloads. Use when the user mentions
  "last screenshot", "see screenshot", "recent screenshot", "show screenshot",
  "last N screenshots", or references viewing screenshots from Downloads.
  Automatically finds and displays the most recent screenshot images sorted
  by creation time.
---

# Screenshot Viewer

Show the user their most recent screenshots from ~/Downloads.

## Arguments

- `$ARGUMENTS` - Optional count of screenshots to show (e.g., "last 4 screenshots")

## Context

Recent image files in ~/Downloads (sorted newest first):

!`find ~/Downloads -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" -o -name "*.gif" \) -print0 2>/dev/null | xargs -0 stat -f "%m %N" 2>/dev/null | sort -rn | head -20 | cut -d" " -f2-`

## Instructions

### Step 1: Determine Count

Parse how many screenshots the user wants from their message:
- "last screenshot" or "see screenshot" = 1
- "last 3 screenshots" or "last N screenshots" = N
- Default to 1 if unclear

### Step 2: Select Files

From the context list above, take the first N file paths (they are already sorted newest-first).

If the list is empty, tell the user no image files were found in ~/Downloads.

### Step 3: Display

Use the Read tool on each selected file path to display the images. The Read tool renders images visually.

Present them in order from most recent to oldest. State the filename for each.
