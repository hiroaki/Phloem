#!/usr/bin/env bash

set -euo pipefail

PHLOEM_URL="${PHLOEM_URL:-http://localhost:3000/route}"
PROFILE="${PROFILE:-car}"
FROM_LAT="${FROM_LAT:-35.68}"
FROM_LON="${FROM_LON:-139.76}"
TO_LAT="${TO_LAT:-35.69}"
TO_LON="${TO_LON:-139.77}"

payload=$(cat <<JSON
{
  "profile": "${PROFILE}",
  "points": [
    { "lat": ${FROM_LAT}, "lon": ${FROM_LON} },
    { "lat": ${TO_LAT}, "lon": ${TO_LON} }
  ],
  "options": {}
}
JSON
)

if command -v jq >/dev/null 2>&1; then
  curl -sS "${PHLOEM_URL}" \
    -H 'Content-Type: application/json' \
    -d "${payload}" | jq
else
  curl -sS "${PHLOEM_URL}" \
    -H 'Content-Type: application/json' \
    -d "${payload}"
  printf '\n'
fi