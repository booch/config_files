#!/usr/bin/env python3
"""Convert downloaded Wayback Machine HTML files to Hugo Markdown posts.

Usage: convert.py <raw_dir> [--hugo-dir <hugo_content_dir>]

Detects CMS type, extracts article content, title, and date from HTML,
converts to Markdown via pandoc, and writes Hugo-compatible .md files.
"""

import argparse
import os
import re
import subprocess
import sys
from datetime import datetime


# CMS detection patterns and their content selectors
CMS_PATTERNS = {
    "wordpress": {
        "detect": [r"wp-content", r"wordpress", r'class="hentry"', r'class="entry-content"'],
        "content_start": r'<div class="entry-content">\s*',
        "content_end": r'\s*</div><!-- \.entry-content -->',
        "title": r'<h1 class="entry-title"[^>]*>(.*?)</h1>',
        "date": r'datetime="([^"]+)"',
    },
    "jekyll": {
        "detect": [r"jekyll", r'class="post-content"'],
        "content_start": r'<div class="post-content">\s*',
        "content_end": r'\s*</div>\s*<!--\s*post-content',
        "title": r'<h1 class="post-title"[^>]*>(.*?)</h1>',
        "date": r'datetime="([^"]+)"',
    },
    "generic": {
        "detect": [],
        "content_start": r"<article[^>]*>\s*",
        "content_end": r"\s*</article>",
        "title": r"<h1[^>]*>(.*?)</h1>",
        "date": r'datetime="([^"]+)"',
    },
}

# Pages to skip (not blog posts)
SKIP_PATTERNS = [
    r"wp-login",
    r"wp-admin",
    r"wp-includes",
    r"xmlrpc",
    r"wp-json",
    r"wp-cron",
    r"/feed",
    r"comments/feed",
    r"robots\.txt",
    r"sitemap",
    r"wlwmanifest",
]

# Pages that are standalone (not posts)
STANDALONE_PATTERNS = [
    r"about",
    r"contact",
    r"privacy",
    r"terms",
]


def detect_cms(html_text):
    """Detect which CMS generated the HTML."""
    for cms_name, patterns in CMS_PATTERNS.items():
        if cms_name == "generic":
            continue
        for pattern in patterns["detect"]:
            if re.search(pattern, html_text, re.IGNORECASE):
                return cms_name
    return "generic"


def extract_content(html_text, cms):
    """Extract article content from HTML based on CMS type."""
    patterns = CMS_PATTERNS[cms]

    start_match = re.search(patterns["content_start"], html_text, re.DOTALL)
    if not start_match:
        return None

    content_start = start_match.end()
    end_match = re.search(patterns["content_end"], html_text[content_start:], re.DOTALL)
    if not end_match:
        return None

    content = html_text[content_start : content_start + end_match.start()]

    # Clean up Wayback URL rewrites
    content = re.sub(r"https?://web\.archive\.org/web/\d+(?:id_)?/", "", content)
    # Remove inline styles
    content = re.sub(r'\s*style="[^"]*"', "", content)

    return content.strip()


def extract_title(html_text, cms):
    """Extract the page title."""
    patterns = CMS_PATTERNS[cms]
    match = re.search(patterns["title"], html_text, re.DOTALL)
    if match:
        title = match.group(1).strip()
        # Remove any nested HTML tags
        title = re.sub(r"<[^>]+>", "", title)
        # Decode HTML entities
        title = title.replace("&#8217;", "'").replace("&#8220;", '"').replace("&#8221;", '"')
        title = title.replace("&amp;", "&").replace("&#039;", "'").replace("&quot;", '"')
        return title

    # Fallback: try <title> tag
    match = re.search(r"<title>([^<]+)</title>", html_text)
    if match:
        title = match.group(1).strip()
        # Remove site name suffix (common pattern: "Post Title | Site Name")
        title = re.split(r"\s*[\|–—]\s*", title)[0].strip()
        return title

    return None


def extract_date(html_text, cms):
    """Extract the publication date."""
    patterns = CMS_PATTERNS[cms]
    match = re.search(patterns["date"], html_text)
    if match:
        return match.group(1)
    return None


def html_to_markdown(html_content):
    """Convert HTML to Markdown using pandoc."""
    result = subprocess.run(
        ["pandoc", "-f", "html", "-t", "markdown", "--wrap=none", "--no-highlight"],
        input=html_content,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"  pandoc error: {result.stderr}", file=sys.stderr)
        return None

    md = result.stdout
    # Clean up excessive blank lines
    md = re.sub(r"\n{3,}", "\n\n", md)
    # Remove trailing whitespace
    md = re.sub(r" +$", "", md, flags=re.MULTILINE)
    return md


def slug_from_filename(filename):
    """Derive a URL slug from the downloaded filename."""
    name = os.path.splitext(filename)[0]
    # Undo the __ separator from download.sh
    parts = name.split("__")
    # The slug is typically the last part of the URL path
    slug = parts[-1] if parts else name
    # Clean up
    slug = re.sub(r"[^a-z0-9-]", "-", slug.lower())
    slug = re.sub(r"-+", "-", slug).strip("-")
    return slug


def is_skip(filename):
    """Check if this file should be skipped entirely."""
    for pattern in SKIP_PATTERNS:
        if re.search(pattern, filename, re.IGNORECASE):
            return True
    return False


def is_standalone(filename):
    """Check if this is a standalone page (not a blog post)."""
    for pattern in STANDALONE_PATTERNS:
        if re.search(pattern, filename, re.IGNORECASE):
            return True
    return False


def make_front_matter(title, date=None, slug=None, draft=False):
    """Generate Hugo YAML front matter."""
    # Escape title for YAML
    if title and any(c in title for c in ':"\'{} [] |>&*?!%@`#,'):
        title = f'"{title}"'

    lines = ["---"]
    if title:
        lines.append(f"title: {title}")
    if date:
        lines.append(f"date: {date}")
    if slug:
        lines.append(f"slug: {slug}")
    lines.append(f"draft: {'true' if draft else 'false'}")
    lines.append("---")
    return "\n".join(lines) + "\n"


def process_file(filepath, hugo_dir):
    """Process a single HTML file."""
    filename = os.path.basename(filepath)

    if is_skip(filename):
        print(f"  SKIP: {filename}")
        return

    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        html_text = f.read()

    if len(html_text) < 100:
        print(f"  SKIP (too small): {filename}")
        return

    cms = detect_cms(html_text)
    title = extract_title(html_text, cms)
    date = extract_date(html_text, cms)
    content_html = extract_content(html_text, cms)

    if not content_html:
        print(f"  SKIP (no content found): {filename}")
        return

    markdown = html_to_markdown(content_html)
    if not markdown:
        print(f"  SKIP (pandoc failed): {filename}")
        return

    slug = slug_from_filename(filename)

    if is_standalone(filename):
        out_dir = hugo_dir
        front_matter = make_front_matter(title)
    else:
        out_dir = os.path.join(hugo_dir, "posts")
        front_matter = make_front_matter(title, date, slug)

    os.makedirs(out_dir, exist_ok=True)
    out_file = os.path.join(out_dir, f"{slug}.md")

    with open(out_file, "w", encoding="utf-8") as f:
        f.write(front_matter)
        f.write("\n")
        f.write(markdown)

    print(f"  OK: {filename} -> {os.path.relpath(out_file, hugo_dir)} ({cms}, {title})")


def main():
    parser = argparse.ArgumentParser(description="Convert Wayback Machine HTML to Hugo Markdown")
    parser.add_argument("raw_dir", help="Directory containing downloaded HTML files")
    parser.add_argument(
        "--hugo-dir",
        default=None,
        help="Hugo content directory (default: <raw_dir>/../content)",
    )
    args = parser.parse_args()

    raw_dir = os.path.abspath(args.raw_dir)
    hugo_dir = args.hugo_dir or os.path.join(os.path.dirname(raw_dir), "content")
    hugo_dir = os.path.abspath(hugo_dir)

    print(f"Source:  {raw_dir}")
    print(f"Output:  {hugo_dir}")
    print()

    html_files = sorted(
        [f for f in os.listdir(raw_dir) if f.endswith(".html")],
    )

    if not html_files:
        print("No HTML files found.")
        sys.exit(1)

    print(f"Processing {len(html_files)} HTML files...")
    print()

    for filename in html_files:
        filepath = os.path.join(raw_dir, filename)
        process_file(filepath, hugo_dir)

    print()
    print("Done!")


if __name__ == "__main__":
    main()
