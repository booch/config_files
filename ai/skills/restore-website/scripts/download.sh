#!/usr/bin/env bash
# Download archived pages and assets from the Wayback Machine.
# Usage: download.sh <domain> <output_dir>
# Downloads HTML pages, RSS feeds, and images using id_ URLs (no Wayback toolbar).

set -euo pipefail

DOMAIN="${1:?Usage: download.sh <domain> <output_dir>}"
OUTPUT_DIR="${2:?Usage: download.sh <domain> <output_dir>}"
CDX_API="https://web.archive.org/cdx/search/cdx"

mkdir -p "${OUTPUT_DIR}"

echo "=== Downloading archived content for ${DOMAIN} ==="

# Download HTML pages
echo ""
echo "--- Downloading HTML pages ---"
curl -s "${CDX_API}?url=${DOMAIN}/*&output=text&fl=timestamp,original&collapse=urlkey&filter=mimetype:text/html&filter=statuscode:200&limit=500" \
  | while read -r timestamp url; do
    # Skip login, admin, and wp-includes pages
    case "${url}" in
      *wp-login*|*wp-admin*|*wp-includes*|*xmlrpc*|*wp-cron*) continue ;;
    esac

    # Generate a filename from the URL path
    path=$(echo "${url}" | sed -E 's|https?://[^/]+||; s|^/||; s|/$||; s|/|__|g')
    [ -z "${path}" ] && path="index"
    path="${path}.html"

    echo "  ${url} -> ${path}"
    curl -s -o "${OUTPUT_DIR}/${path}" "https://web.archive.org/web/${timestamp}id_/${url}"
done

# Download RSS/Atom feeds
echo ""
echo "--- Downloading feeds ---"
curl -s "${CDX_API}?url=${DOMAIN}/*&output=text&fl=timestamp,original&collapse=urlkey&filter=statuscode:200&limit=500" \
  | grep -iE 'text/xml|application/rss|application/atom|/feed' \
  | while read -r timestamp url _rest; do
    path=$(echo "${url}" | sed -E 's|https?://[^/]+||; s|^/||; s|/$||; s|/|__|g')
    [ -z "${path}" ] && path="feed"
    path="${path}.xml"

    echo "  ${url} -> ${path}"
    curl -s -o "${OUTPUT_DIR}/${path}" "https://web.archive.org/web/${timestamp}id_/${url}"
done

# Download images
echo ""
echo "--- Downloading images ---"
mkdir -p "${OUTPUT_DIR}/images"
curl -s "${CDX_API}?url=${DOMAIN}/*&output=text&fl=timestamp,original,mimetype&collapse=urlkey&filter=statuscode:200&limit=500" \
  | grep -iE 'image/(jpeg|png|gif|webp|svg|ico)' \
  | while read -r timestamp url _mimetype; do
    filename=$(basename "${url}" | sed 's|?.*||')
    [ -z "${filename}" ] && continue

    echo "  ${url} -> images/${filename}"
    curl -s -o "${OUTPUT_DIR}/images/${filename}" "https://web.archive.org/web/${timestamp}id_/${url}"
done

echo ""
echo "=== Download complete ==="
echo "Files saved to: ${OUTPUT_DIR}"
ls "${OUTPUT_DIR}"
