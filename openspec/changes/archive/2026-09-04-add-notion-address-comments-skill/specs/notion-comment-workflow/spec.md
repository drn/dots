## ADDED Requirements

### Requirement: Notion Comment-Addressing Skill

The repository SHALL provide a `notion-address-comments` skill that, given a Notion
page with open inline comment threads, reads each unresolved thread, edits the page to
address what the thread is asking for, and replies to the thread with a short summary
of the change.

The skill SHALL:
- Fetch open comment threads rather than assuming all comments need action — resolved
  threads are excluded by default and SHALL NOT be reprocessed.
- Re-fetch the page's current content immediately before building each edit, since a
  stale copy (from an earlier turn, or from the user's own manual edits between turns)
  produces a failed text match.
- Track which threads have already been replied to, and only act on a thread again
  when it has a newer comment posted after the skill's last reply on it.
- Reply to each addressed thread with a short note describing what changed.
- State explicitly, when no resolve-thread tool is available, that threads remain open
  for the user to resolve manually rather than implying they were closed.

#### Scenario: Addressing open comment threads on a Notion page

- **WHEN** a user invokes `notion-address-comments` on a Notion page with unresolved
  inline comments
- **THEN** Claude reads each open thread, edits the page to address it, and replies to
  the thread summarizing the change

#### Scenario: Re-invoking after a prior pass with no new feedback

- **WHEN** a thread already has a reply from a previous invocation and no newer comment
  since that reply
- **THEN** the skill SHALL NOT reprocess or reply to that thread again

#### Scenario: No resolve-thread capability available

- **WHEN** the skill has addressed a thread and no tool exists to mark it resolved
- **THEN** the skill SHALL tell the user the thread remains open for manual resolution
  in the Notion UI, rather than implying it was resolved
