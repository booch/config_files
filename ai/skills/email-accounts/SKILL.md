---
name: craig-email
description: |
  Access Craig's 3 email accounts — Gmail (personal), BoochTek (business), and SLUUG (old personal). Use this skill whenever the user asks to access emails, or when a task would benefit from email data (receipt hunting, conference confirmations, subscription audits, etc). Knows folder structures, MCP tool mappings, search syntax differences, and gotchas for each account.
---

# Craig's Email Accounts

Craig has 3 email accounts connected via separate MCP servers. Each has different tools, folder structures, and quirks.

## Account overview

| Account | Address | MCP server | Transport | Primary use |
|---|---|---|---|---|
| **Gmail** | `craig.buchek@gmail.com` | claude.ai hosted Gmail MCP | HTTPS (OAuth) | Personal email, conference registrations, donation receipts, software subscriptions |
| **BoochTek** | `craig@boochtek.com` | Fastmail's official MCP at `https://api.fastmail.com/mcp` | HTTPS (OAuth) | Business email, client work, business expense receipts |
| **SLUUG** | `craig@buchek.com`, `*@craigbuchek.com` | `@codefuturist/email-mcp` via `~/bin/sluug-mail-mcp` wrapper | stdio (IMAP) | Old personal email address with vanity domains |

The local audit script at `~/Personal/Email/startup.sh` verifies all three are healthy.

## Identifying the right MCP tools

MCP tool names include server-specific prefixes that may change between sessions (especially Gmail, which has a UUID prefix). To find the right tools:

1. Check available tools for keywords: `gmail`, `fastmail`, `sluug-mail`
2. If tools are deferred, use ToolSearch to load them before calling
3. The tool naming patterns are stable within a session once loaded

### Gmail (personal)

**Key tools:** `search_threads` (or `search_messages`), `get_thread`, `create_draft`, `list_labels`

**Search syntax:** Gmail uses its own query language, not IMAP. Examples:
- `from:anthropic after:2025/1/1 before:2026/1/1`
- `"tax receipt" OR "tax-deductible" OR "501(c)(3)"`
- `subject:confirmation from:southwest`
- `label:important has:attachment filename:pdf`

**Gotchas:**
- Gmail returns threads, not individual messages
- Results are reverse-chronological by default
- Gmail MCP has rate limits; batch searches by theme rather than doing hundreds of individual message reads

### BoochTek / Fastmail (business)

Uses Fastmail's **official** remote MCP server announced 2026-04-23 at `https://api.fastmail.com/mcp`. OAuth-based with three scope tiers: read-only / write / send.

**Key tools:** Enumerate the first time you use the server in a session by listing tools whose names contain `fastmail`. Fastmail's blog post did not document the canonical tool names — they may evolve. Update this skill once you've verified the actual names.

**Important folders:**
- `Business Expenses` — receipts for software, services, domains, subscriptions, etc
- `Travel` — booking confirmations, itineraries
- `Conferences` — conference-related correspondence

**Gotchas:**
- When listing emails, specify the folder/mailbox explicitly — without it you typically get INBOX only.
- Attachments need a separate fetch call after the listing tool returns attachment IDs.
- If `claude mcp list` shows `Needs authentication`, run `/mcp` and complete the OAuth consent screen.

### SLUUG mail (old personal)

Uses the NPM `@codefuturist/email-mcp@0.2.1` package (installed globally; binary `email-mcp`) invoked through `~/bin/sluug-mail-mcp`. The wrapper exports `MCP_EMAIL_*` env vars with the password pulled from macOS Keychain (service name `sluug-mail-mcp`).

**Server config:** `mail.sluug.org:993` (IMAP SSL) and `mail.sluug.org:465` (SMTP SSL).

**Login identity:** the From: address is `craig@buchek.com`, but the **IMAP/SMTP login username is `booch@sluug.org`** (the SLUUG account, not the vanity address). Set via `MCP_EMAIL_USERNAME` in the wrapper. If that ever stops working, the fallback is the bare local part `booch`.

**Key tools:** `list_emails`, `get_email`, `search_emails`, `list_mailboxes`, `find_email_folder` (verify in-session).

**Search syntax:** IMAP-based search via the sluug-mail MCP.

**Diagnostics:** the wrapper passes args through to the underlying CLI, so `~/bin/sluug-mail-mcp test sluug` runs the package's IMAP+SMTP login check directly. The `startup.sh` audit calls this so a stale password doesn't silently pass the MCP-level health check.

**Gotchas:**
- When fetching individual emails, the full body can be very large. Use `maxLength` parameters if available to avoid blowing up context.
- TLS chain quirk: SLUUG's mail server ships only the leaf cert without the Let's Encrypt R12 intermediate. The wrapper sets `NODE_EXTRA_CA_CERTS=~/.config/email-mcp/lets-encrypt-r12.pem` to compensate. When LE rotates intermediates, re-download from <https://letsencrypt.org/certs/> and update the pem. Proper fix would be server-side (configure mail.sluug.org to serve the full chain).
- **Auth lockout**: SLUUG runs fail2ban-style IP blocking on the IMAP port. After 2–3 failed logins, the server starts refusing TCP entirely (`ECONNREFUSED` on 993). The ban typically lifts in 10 min to ~1 hour. So: **never spray-test username/password variants** — confirm the exact credentials before retrying. If you do get banned, switch to a phone hotspot or ask the SLUUG admin to lift it.
- **MCP-handshake ≠ IMAP-login**: `claude mcp list` reports SLUUG as "✓ Connected" the moment the stdio MCP server starts. That does NOT mean credentials are accepted — IMAP login is deferred until first tool call. Always confirm with `~/bin/sluug-mail-mcp test sluug` (or just run `startup.sh`, which does this for you).
- "SLUUG" may be case-sensitive in some places.
