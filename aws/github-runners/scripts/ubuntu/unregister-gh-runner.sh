#!/usr/bin/env bash
set -euo pipefail

# === CONFIGURATION ===
REPO="herondlabs/herond-browser"             # Format: org/repo
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
RUNNER_DIR="/opt/github-runner"
GITHUB_PAT="${GITHUB_PAT}"                   # Set as env var before running

# === HEADERS ===
AUTH_HEADER="Authorization: Bearer $GITHUB_PAT"
ACCEPT_HEADER="Accept: application/vnd.github+json"
API_VERSION="X-GitHub-Api-Version: 2022-11-28"

# === FETCH TOKEN FOR REMOVAL ===
echo "🔑 Getting unregister token..."
TOKEN=$(curl -s -X POST \
  -H "$AUTH_HEADER" \
  -H "$ACCEPT_HEADER" \
  -H "$API_VERSION" \
  "https://api.github.com/repos/$REPO/actions/runners/remove-token" | jq -r '.token')

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "❌ Failed to get remove token."
  exit 1
fi
echo "✅ Got remove token"

# === GET RUNNER LIST ===
echo "🔍 Checking registered runners on GitHub..."
RUNNERS_JSON=$(curl -s -H "$AUTH_HEADER" -H "$ACCEPT_HEADER" -H "$API_VERSION" \
  "https://api.github.com/repos/$REPO/actions/runners")

RUNNER_ID=$(echo "$RUNNERS_JSON" | jq ".runners[] | select(.name==\"$INSTANCE_ID\") | .id")

if [[ -z "$RUNNER_ID" ]]; then
  echo "⚠️  Runner '$INSTANCE_ID' not found on GitHub"
else
  # === DELETE RUNNER FROM GITHUB ===
  echo "🗑️  Deleting runner ID: $RUNNER_ID"
  curl -s -X DELETE \
    -H "$AUTH_HEADER" \
    -H "$ACCEPT_HEADER" \
    -H "$API_VERSION" \
    "https://api.github.com/repos/$REPO/actions/runners/$RUNNER_ID"
  echo "✅ Removed runner '$INSTANCE_ID' from GitHub"
fi

# === STOP LOCAL RUN PROCESS IF RUNNING ===
if pgrep -f "run.sh" > /dev/null; then
  echo "🛑 Stopping local runner process..."
  pkill -f "run.sh"
fi

# === UNREGISTER LOCALLY ===
echo "🧽 Running local unregistration with token..."
cd "$RUNNER_DIR"
./config.sh remove --unattended --token "$TOKEN"

echo "✅ Local runner unregistered and cleaned."

# === DELETE LOCAL CONFIG FILE ===
if [[ -d "$RUNNER_DIR/.runner" ]]; then
  echo "🧹 Deleting local runner config..."
  rm -rf "$RUNNER_DIR/.runner"
fi
