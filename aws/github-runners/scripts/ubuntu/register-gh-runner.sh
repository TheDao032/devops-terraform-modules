#!/usr/bin/env bash
set -euo pipefail

# === CONFIGURATION ===
REPO="herondlabs/herond-browser"        # Format: org/repo
GITHUB_PAT="${GITHUB_PAT}"       # Or hardcode (not recommended)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
RUNNER_DIR="$HOME/actions-runner"

cd "$RUNNER_DIR"

# === GET REGISTRATION TOKEN ===
TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $GITHUB_PAT" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${REPO}/actions/runners/registration-token \
    | jq -r .token)

echo "✅ Received runner token"

# === CONFIGURE RUNNER ===
./config.sh --unattended \
  --replace \
  --url "https://github.com/${REPO}" \
  --token "$TOKEN" \
  --name "$INSTANCE_ID" \
  --labels "$INSTANCE_ID" \
  --work "_work"

# === START RUNNER ===
echo "🚀 Starting runner..."
./run.sh
