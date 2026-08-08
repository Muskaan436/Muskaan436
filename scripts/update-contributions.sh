#!/usr/bin/env bash
set -euo pipefail

USERNAME="Muskaan436"
README="README.md"
START_MARKER="<!-- CONTRIBUTIONS:START -->"
END_MARKER="<!-- CONTRIBUTIONS:END -->"
TABLE_FILE="$(mktemp)"

# Owners to exclude from the table in addition to $USERNAME's own repos
EXCLUDED_OWNERS=("Team-Vertex-GrabHack")

echo "Fetching merged PRs authored by $USERNAME..."

prs=$(gh search prs --author "$USERNAME" --json title,url,repository,closedAt,state --limit 100)

excluded_json=$(printf '%s\n' "${EXCLUDED_OWNERS[@]}" | jq -R . | jq -s .)

rows=$(echo "$prs" | jq -r --arg user "$USERNAME" --argjson excluded "$excluded_json" '
  [.[] | select(.state == "merged")
       | select((.repository.nameWithOwner | startswith($user + "/")) | not)
       | select((.repository.nameWithOwner | split("/")[0]) as $owner | ($excluded | index($owner)) | not)]
  | sort_by(.closedAt) | reverse
  | .[] |
  "| [\(.repository.nameWithOwner)](https://github.com/\(.repository.nameWithOwner)) | [\(.title)](\(.url)) | \(.closedAt[:10]) |"
')

{
  echo "| Repo | Pull Request | Merged |"
  echo "|------|--------------|--------|"
  if [ -z "$rows" ]; then
    echo "| _No external merged PRs found yet_ | | |"
  else
    echo "$rows"
  fi
} > "$TABLE_FILE"

awk -v start="$START_MARKER" -v end="$END_MARKER" -v tablefile="$TABLE_FILE" '
  $0 == start { print; while ((getline line < tablefile) > 0) print line; skip=1; next }
  $0 == end { print; skip=0; next }
  skip { next }
  { print }
' "$README" > "$README.tmp"

mv "$README.tmp" "$README"
rm -f "$TABLE_FILE"

echo "Done."
