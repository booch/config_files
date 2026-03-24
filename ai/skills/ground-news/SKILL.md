---
name: ground-news
description: Fetch news stories from Ground News with bias ratings and blindspot analysis. Use when aggregating news for the morning briefing or when the user wants news with media bias context.
---

# Ground News Skill

Fetch and summarize news from Ground News, emphasizing their unique bias ratings and blindspot analysis.

## Prerequisites

- Ground News account (Pro or Premium recommended)
- API key stored in 1Password at `op://Personal/Ground News API/api_key`
- If no API is available, fall back to RSS or email digest parsing

## Usage

### With API (preferred)

```bash
API_KEY=$(op read 'op://Personal/Ground News API/api_key' 2>/dev/null)
```

If the API key is available, use it to fetch:
- Top stories with bias ratings (left, center, right coverage)
- Blindspot stories (covered by one side but not the other)
- User's personalized feed (if the API supports it)

### Fallback: RSS

If no API key is available, check for Ground News RSS feeds:
- Use the RSS MCP to fetch from any available Ground News feed URLs
- Note: RSS feeds may not include bias ratings

### Fallback: Email Digest

If Ground News sends email digests:
- Use the IMAP MCP to find recent Ground News emails
- Parse article titles, links, and any bias indicators
- Mark the email as read after processing

## Output Format

For each story, provide:
- **Headline**: The story title
- **Summary**: 1-2 sentence summary
- **Bias Rating**: Left / Center / Right coverage breakdown (if available)
- **Blindspot**: Whether this story is underreported by any side (if available)
- **Sources**: Number of sources covering this story
- **Link**: URL to the Ground News story page

## Integration

This skill is used by the `/morning` command as part of the General News section.
The morning briefing will call this skill and incorporate its output into the HTML briefing.

## TODO

- [ ] Determine if Ground News has a public API
- [ ] If not, implement RSS or email digest fallback
- [ ] Add support for topic filtering (e.g., tech, politics, science)
- [ ] Add support for "My Feed" personalization
