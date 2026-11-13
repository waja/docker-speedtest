#!/usr/bin/env bash
# .github/scripts/check-release-image-history.sh
# Fail if the latest publication record for a tag points to another commit.
set -euo pipefail

API="${1:?API path required, e.g. repos/owner/repo}"
RELEASE_TAG="${2:?Release tag required}"
RELEASE_SHA="${3:?Release commit SHA required}"
ALLOW_TAG_REPLACEMENT="${4:-false}"
PUBLISH_PREFIX="Docker Image CI release-publish-${RELEASE_TAG}-"

run_lines=$(gh api --paginate --method GET \
	"$API/actions/workflows/docker.image.yml/runs" \
	-F per_page=100 \
	--jq '.workflow_runs[] |
    {id,event,head_sha,head_branch,display_title,status,conclusion,created_at}')

latest=$(jq -s -c --arg tag "$RELEASE_TAG" \
	--arg prefix "$PUBLISH_PREFIX" '
    [.[] | select(
      ((.head_branch == $tag) and
        (.event == "push" or .event == "workflow_dispatch"))
      or ((.display_title // "") | startswith($prefix))
    )]
    | sort_by(.created_at) | last // empty
  ' <<<"$run_lines")

if [[ -z "$latest" ]]; then
	echo "No previous publication record found for $RELEASE_TAG."
	exit 0
fi

latest_sha=$(jq -r --arg prefix "$PUBLISH_PREFIX" '
  if ((.display_title // "") | startswith($prefix))
  then .display_title[($prefix | length):][:40]
  else .head_sha end
' <<<"$latest")

if [[ "$latest_sha" != "$RELEASE_SHA" ]]; then
	if [[ "$ALLOW_TAG_REPLACEMENT" == "true" ]]; then
		echo "::warning::Explicit override enabled: $RELEASE_TAG will be republished from a different commit."
		jq '{id,head_sha,head_branch,display_title,status,conclusion}' <<<"$latest"
		exit 0
	fi
	echo "::error::The latest publication for $RELEASE_TAG uses another commit."
	echo "Refusing to replace an image that may already be published."
	jq '{id,head_sha,head_branch,display_title,status,conclusion}' <<<"$latest"
	exit 1
fi

echo "Latest publication record matches $RELEASE_SHA."
