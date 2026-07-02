#!/bin/bash
OUT_DIR="$HOME/.cache/quickshell/github_cards"
mkdir -p "$OUT_DIR"

USER=$(jq -r '.profileGithub // "widev71"' "$HOME/.config/hypr/settings.json" 2>/dev/null || echo "widev71")
THEME="transparent"
BASE_URL="https://github-profile-summary-cards.vercel.app/api/cards"

CARDS=("stats" "most-commit-language" "repos-per-language" "productive-time" "profile-details")

for card in "${CARDS[@]}"; do
    curl -s -L "${BASE_URL}/${card}?username=${USER}&theme=${THEME}" | sed 's/#00000000/none/g' > "$OUT_DIR/${card}.svg"
done

