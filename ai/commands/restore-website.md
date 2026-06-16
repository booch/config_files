---
description: Restore a lost website from the Wayback Machine and convert to a Hugo static site
---

Restore a website from the Internet Archive's Wayback Machine.

Use the `restore-website` skill for the full workflow. Follow the skill's phases in order:

1. **Inventory** — Run the inventory script for the domain specified by the user (or ask which domain)
2. **Review** — Present the inventory to the user and confirm which pages to recover
3. **Download** — Download all confirmed pages using the download script
4. **Convert** — Convert HTML to Hugo Markdown using the convert script
5. **Hugo setup** — Initialize Hugo site, install theme, configure
6. **Images** — Download and localize any referenced images
7. **Review** — Spot-check the output, build the site, present summary

ARGUMENTS: $ARGUMENTS
