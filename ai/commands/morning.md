---
description: Generate a morning briefing with calendar, projects, email, news, and Homebrew updates
---

# Morning Briefing

Generate a comprehensive morning briefing. Write it as Markdown (stored for history), convert to HTML via `md2html`, and open it in the browser.

## Configuration

Config directory: `${XDG_CONFIG_HOME:-$HOME/.config}/morning-briefing/`

If it does not exist, create it and generate starter config files (see Bootstrap section below).

Detect machine context early:

```bash
MORNING_SCRIPT_CONTEXT=$(hostname | cut -d'.' -f1)
```

Source `config.sh` from the config directory to load all settings.

## Steps

Delegate to subagents for independent data gathering (steps 1-6 can run in parallel). Then synthesize everything into the final briefing (step 7).

### 1. Calendar

Use the CalDAV MCP (or `icalBuddy` CLI if available) to fetch:

- **Today's events**: All events for today, with times, locations, and attendees
- **Noteworthy upcoming**: Scan the next 7 days for events matching keywords: conference, presentation, deadline, release, launch, interview, doctor, appointment, travel, flight, birthday, anniversary

### 2. Project Status

Read `~/Personal/Projects/Current.md` (also check `~/Documents/Personal/Projects/Current.md` as a fallback).

Parse the **In Progress** section. For each item:

- Extract the project name and any sub-items
- Items with `==highlights==` (Obsidian syntax) deserve attention — flag them prominently in the briefing
- Items with `✔️` checkmarks indicate completed sub-tasks
- If the item links to another file (e.g., `Grammy.md`, `Stone.md`), read that file and extract:
  - Recent changes or updates
  - Next steps or action items
  - Anything near completion or with pending commits
- For items referencing git repos, run `git status` and `git log --oneline -3` to check for uncommitted work or recent activity

**Deadline detection**: When items mention dates or "before [date]" deadlines:
- Flag deadlines that are within 7 days
- Create calendar reminders for deadline items that don't already have calendar events

Synthesize into a "Where You Left Off" summary:
- Items that deserve attention (highlighted)
- Items near completion (most sub-items checked off)
- Upcoming deadlines
- Items with uncommitted git changes

### 3. Email Summaries

Use the IMAP MCP (`imap-mcp`) to connect to each configured email account.

For each account:
- Connect using credentials from 1Password: `op read 'op://vault/item/field'`
- Fetch unread messages from the Inbox (last 24 hours or up to 10, whichever is fewer)
- For each message: sender, subject, date, and a 1-2 sentence summary of the body
- Flag anything that looks urgent or time-sensitive

**Medium emails**: Extract article titles and links. Then mark as read and delete the email.

**AARP emails**: Extract article titles and links of potential interest. Then mark as read and delete the email.

Personal accounts (when `MORNING_SCRIPT_CONTEXT` matches the personal Mac):
- craig@sluug.org
- craig@slashmail.org
- boochtek@slashmail.org

Work accounts (when `MORNING_SCRIPT_CONTEXT` matches the work Mac):
- (configured in config file)

### 4. General News (target: ~1 printed page)

Use the RSS MCP (`rss-mcp`) to fetch from configured general news feeds. Also use web search to fill gaps.

Sources (configurable):
- Reuters, AP, NPR, BBC, NYT
- CNN, NBC News, Al Jazeera
- PBS News Hour (fetch transcript summaries or recent segment descriptions)
- Ground News (if API key available, use the `ground-news` skill)

For each story: headline, 1-2 sentence summary, source, link, and an image URL if available.

Curate to ~8-10 stories. Prioritize diversity of topics and sources.

### 5. Tech News (target: ~2 printed pages)

Use the RSS MCP to fetch from configured tech feeds:
- Ars Technica
- Mac Rumours
- Ruby Weekly
- Hacker News (top 5-10)
- Dev.to (trending)

Also search for recent news on:
- AI/LLM usage in software development workflows
- AI for engineering leadership and team productivity
- Ruby, Rails, Elixir, Phoenix updates
- Obsidian and Markdown Oxide / Zettelkasten tooling
- Software engineering best practices and Agile

For each story: headline, 1-2 sentence summary, source, link, and relevance tag (e.g., "AI", "Ruby", "Leadership").

Curate to ~15-20 stories. Group by topic.

### 6. Homebrew Updates

Delegate to the `/brew-update` command. Capture its output for inclusion in the briefing.

### 7. Generate and Open the Briefing

Write the briefing as **Markdown** and save it for history. Then convert to HTML and open it in the browser.

**Markdown file** (stored permanently):
```
${XDG_DATA_HOME:-$HOME/.local/share}/morning-briefing/YYYY-MM-DD.md
```

Create the directory if it doesn't exist.

**Document structure** (in this order):

```markdown
# Morning Briefing — [Today's Date]

## Calendar
[Today's events, then noteworthy upcoming]

## Where You Left Off
[Attention items, near-completion, deadlines, uncommitted work]

## Email
### [account 1] (N unread)
[Urgent items first, then summaries]
### [account 2]
...

## General News
[~8-10 stories with images, links]

## Tech News
### AI & Leadership
### Ruby / Elixir / Web
### Tools & Productivity
### Other
[~15-20 stories grouped by topic, with images, links]

## Homebrew Updates
[Packages upgraded, notable changes]
```

Use embedded HTML within Markdown where needed (images with sizing, styled callout boxes for urgent items, etc.).

**Convert and open** (no need to save the HTML):
```bash
OUTPUT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/morning-briefing"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/morning-briefing"
TODAY=$(date +%Y-%m-%d)

md2html "$OUTPUT_DIR/$TODAY.md" --open
# Or with custom CSS:
# md2html "$OUTPUT_DIR/$TODAY.md" --css "$CONFIG_DIR/style.css" --open
```

The `md2html` tool handles `==highlights==`, footnotes, task lists, embedded HTML, and wraps output in a full HTML document with clean default CSS.

## Bootstrap (First Run)

If the config directory doesn't exist, create it with starter config files and tell the user to customize them. The config system works as follows:

`config.sh` is the entry point — it sources all other config files in order. Each file has a single responsibility:

- **`config.sh`** — Entry point. Detects machine context, sources other config files, sets defaults for anything not yet configured. The `/morning` command sources this first.
- **`context.env`** — Machine-specific settings. Maps hostname to `MORNING_AI_PROVIDER` (`claude` or `openai`). Also sets the output directory and any machine-specific overrides.
- **`email.env`** — IMAP account list per context (personal vs work). Defines server hostnames and usernames. Passwords are never stored here — they're fetched from 1Password at runtime via `op read`.
- **`news.sh`** — RSS feed URLs for general and tech news. Defines how many items per feed, calendar lookahead days, and keywords for "noteworthy" events.
- **`local.env`** — Optional. Git-ignored. For anything you don't want in version control (local overrides, temporary settings).

On first run, generate these files with sensible defaults populated from this command's configuration (email accounts, news sources, etc.) and tell the user which values they should verify or customize.

## Automation

A wrapper script at `~/.local/bin/morning-briefing.sh` handles:
1. Sourcing the config
2. Selecting the AI provider based on `MORNING_SCRIPT_CONTEXT`
3. Invoking `claude /morning` or `codex /morning`

A launchd plist at `~/Library/LaunchAgents/com.craigbuchek.morning-briefing.plist` runs the wrapper at 8:00 AM local time.

## Error Handling

- If an MCP is not available, skip that section and note it in the briefing
- If 1Password is not authenticated, skip email and note it
- If a feed is unreachable, skip it and note it
- Always generate the briefing even if some sections are incomplete
- Log errors to `${XDG_STATE_HOME:-$HOME/.local/state}/morning-briefing/errors.log`

## Subagent Delegation

Use subagents for parallel data gathering:
- **Subagent 1**: Calendar (CalDAV MCP or icalBuddy)
- **Subagent 2**: Project status (file reading + git)
- **Subagent 3**: Email summaries (IMAP MCP)
- **Subagent 4**: General news (RSS MCP + web search)
- **Subagent 5**: Tech news (RSS MCP + web search)
- **Subagent 6**: Homebrew updates (delegate to `/brew-update`)

The main agent synthesizes all subagent results into the final Markdown document.
