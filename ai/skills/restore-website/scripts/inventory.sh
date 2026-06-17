#!/usr/bin/env bash
# Inventory all archived content for a domain from the Wayback Machine CDX API.
# Usage: inventory.sh <domain>
# Output: Structured summary of archived pages, assets, and feeds.

set -euo pipefail

DOMAIN="${1:?Usage: inventory.sh <domain>}"
CDX_API="https://web.archive.org/cdx/search/cdx"

echo "=== Wayback Machine Inventory for ${DOMAIN} ==="
echo ""

echo "--- HTML Pages (200 OK) ---"
curl -s "${CDX_API}?url=${DOMAIN}/*&output=text&fl=timestamp,original,mimetype,statuscode&collapse=urlkey&filter=mimetype:text/html&filter=statuscode:200&limit=500"
echo ""

echo "--- RSS/Atom Feeds ---"
curl -s "${CDX_API}?url=${DOMAIN}/*&output=text&fl=timestamp,original,mimetype,statuscode&collapse=urlkey&filter=statuscode:200&limit=500" \
  | grep -iE 'text/xml|application/rss|application/atom|/feed'
echo ""

echo "--- CSS Stylesheets ---"
curl -s "${CDX_API}?url=${DOMAIN}/*&output=text&fl=timestamp,original,mimetype,statuscode&collapse=urlkey&filter=mimetype:text/css&filter=statuscode:200&limit=100"
echo ""

echo "--- Images ---"
curl -s "${CDX_API}?url=${DOMAIN}/*&output=text&fl=timestamp,original,mimetype,statuscode&collapse=urlkey&filter=statuscode:200&limit=500" \
  | grep -iE 'image/(jpeg|png|gif|webp|svg|ico)'
echo ""

echo "--- Date Range ---"
FIRST=$(curl -s "${CDX_API}?url=${DOMAIN}/*&output=text&fl=timestamp&limit=1&sort=asc" | head -1)
LAST=$(curl -s "${CDX_API}?url=${DOMAIN}/*&output=text&fl=timestamp&limit=1&sort=desc" | head -1)
echo "Earliest capture: ${FIRST}"
echo "Latest capture:   ${LAST}"
echo ""

TOTAL=$(curl -s "${CDX_API}?url=${DOMAIN}/*&output=text&fl=timestamp&collapse=urlkey" | wc -l | tr -d ' ')
echo "Total unique URLs: ${TOTAL}"
