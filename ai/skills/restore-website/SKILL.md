---
name: restore-website
description: This skill should be used when the user asks to "restore a website", "recover a site from the Wayback Machine", "download from archive.org", "rebuild a lost website", "convert a WordPress site to Hugo", or mentions recovering lost web content from the Internet Archive. Guides the full workflow from Wayback Machine inventory through Hugo site generation.
---

# Restore Website from Wayback Machine

Recover a lost website from the Internet Archive's Wayback Machine, convert its content to Markdown, and set up a Hugo static site.

## Prerequisites

Verify these tools are installed before starting:
- `curl` (for Wayback Machine API and downloads)
- `pandoc` (for HTML-to-Markdown conversion)
- `hugo` (for static site generation)
- `git` (for version control and theme installation)

Install any missing tools via Homebrew: `brew install pandoc hugo git`

## Workflow

### Phase 1: Inventory

Query the Wayback Machine CDX API to discover all archived content for the domain.

Run the inventory script to get a structured summary:

```bash
bash ${CLAUDE_SKILL_ROOT}/scripts/inventory.sh <domain>
```

This produces:
- List of all archived HTML pages with timestamps
- List of archived assets (CSS, JS, images)
- RSS/Atom feed URLs if available
- Date range of captures

Review the inventory with the user to:
- Confirm which pages are actual content (vs. login pages, admin, etc.)
- Identify the blog post URL pattern (e.g., `/YYYY/MM/slug`)
- Note any RSS/Atom feeds for cleaner content extraction

### Phase 2: Download

Download all content pages using the Wayback Machine's `id_` URL modifier, which returns the original content without the Wayback toolbar injection.

URL format: `https://web.archive.org/web/<timestamp>id_/<original_url>`

Run the download script:

```bash
bash ${CLAUDE_SKILL_ROOT}/scripts/download.sh <domain> <output_dir>
```

This downloads:
- All HTML pages identified in the inventory
- RSS/Atom feeds (for cleaner article content)
- CSS stylesheets
- Images referenced in the pages

**Important:** Always use the `id_` suffix. Without it, Wayback injects toolbar HTML that corrupts pandoc conversion.

### Phase 3: Extract and Convert

For each downloaded HTML page, extract the article content and convert to Markdown.

Run the conversion script:

```bash
python3 ${CLAUDE_SKILL_ROOT}/scripts/convert.py <output_dir>
```

The script:
1. Detects the CMS type (WordPress, Jekyll, etc.) from HTML structure
2. Extracts article content from the appropriate container element
3. Extracts title and publication date from HTML metadata
4. Strips inline styles and Wayback URL rewrites
5. Converts to Markdown via pandoc
6. Generates Hugo front matter (title, date, slug, draft: false)
7. Writes to `content/posts/<slug>.md`

For pages that are not blog posts (About, Contact, etc.), place them directly in `content/` rather than `content/posts/`.

**Manual review required:** After conversion, spot-check 2-3 posts for:
- Correct title and date in front matter
- Clean Markdown (no leftover HTML cruft)
- Working links (strip any remaining Wayback URL prefixes)
- Image references (note any broken/missing images)

### Phase 4: Set Up Hugo Site

Initialize the Hugo site and configure it:

1. Run `hugo new site <directory> --force` (use `--force` if files already exist)
2. Initialize git: `git init`
3. Install a theme as a git submodule (default: PaperMod)
4. Configure `hugo.toml` with:
   - Site title (from the original site's `<title>` or RSS `<title>`)
   - Theme name
   - Menu items (About page, Archive)
   - Basic params (light theme, reading time, no share buttons)
5. Create `content/archives.md` with archives layout
6. Create `.gitignore` (exclude `public/`, `.hugo_build.lock`, and the raw download directory)
7. Build and verify: `hugo --gc --minify`

### Phase 5: Handle Images

Check all Markdown files for image references:

```bash
grep -r '!\[' content/ --include='*.md'
```

For each image:
1. If the URL is a Wayback URL or still-live URL, download to `static/images/`
2. If the URL is dead (Facebook CDN, expired hosting), mark with `<!-- Image not found: description -->`
3. Update Markdown references to use local paths (`/images/filename.jpg`)
4. Verify downloaded files are actual images: `file static/images/*`

### Phase 6: Review and Commit

Present a summary to the user:
- Number of pages recovered
- Any missing content or broken images
- Theme choice and configuration
- Suggest running `hugo server -D` to preview

## Tips

- **RSS feeds** often contain cleaner article HTML than the page itself (no theme chrome, no sidebar). Prefer RSS content when available, falling back to HTML scraping.
- **Facebook CDN images** from old posts are almost always gone. Check the user's Photos library or ask if they have originals.
- **WordPress detection:** Look for `wp-content` in paths, `hentry` class on articles, `entry-content` div for article body, `entry-title` for title, `entry-date` with `datetime` attribute for dates.
- **Multiple captures:** The CDX API returns multiple timestamps per URL. Use `collapse=urlkey` to deduplicate, or pick the most recent successful capture.
- **Theme alternatives:** PaperMod is the default. For WordPress Twenty Twelve aesthetics, suggest Mainroad or hugo-paper.
