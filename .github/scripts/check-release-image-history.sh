#!/usr/bin/env bash
# .github/scripts/check-release-image-history.sh
# Fail if the latest publication-stage attempt for a tag points to another commit.
set -euo pipefail

API="${1:?API path required, e.g. repos/owner/repo}"
RELEASE_TAG="${2:?Release tag required}"
RELEASE_SHA="${3:?Release commit SHA required}"
ALLOW_TAG_REPLACEMENT="${4:-false}"
CURRENT_RUN_ID="${5:-}"
REJECT_SAME_SHA_RECREATION="${6:-false}"
PUBLISH_PREFIX="Docker Image CI release-publish-${RELEASE_TAG}-"

run_lines=$(gh api --paginate --method GET \
	"$API/actions/workflows/docker.image.yml/runs" \
	-F per_page=100 \
	--jq '.workflow_runs[] |
		{id,run_attempt,event,head_sha,head_branch,display_title,status,conclusion,created_at}')

# Inspect every attempt for each matching run ID. A later retry may be
# cancelled before the release job starts, but an earlier attempt may already
# have pushed the image. Only attempts whose Build and push step was not
# skipped count as publication history; rejected guard runs remain excluded.
latest=""
latest_started=""
latest_id=""
latest_attempt=0
while IFS= read -r candidate; do
	candidate_id=$(jq -r '.id' <<<"$candidate")
	max_attempt=$(jq -r '.run_attempt // 1' <<<"$candidate")
	for ((attempt = 1; attempt <= max_attempt; attempt++)); do
		attempt_info=$(gh api "$API/actions/runs/$candidate_id/attempts/$attempt" --jq '{status,run_started_at}')
		attempt_status=$(jq -r '.status' <<<"$attempt_info")
		attempt_started=$(jq -r '.run_started_at' <<<"$attempt_info")
		if [[ -n "$CURRENT_RUN_ID" && "$attempt_status" != "completed" ]]; then
			continue
		fi
		if [[ -z "$attempt_started" || "$attempt_started" == "null" ]]; then
			continue
		fi
		job_lines=$(gh api --paginate --method GET \
			"$API/actions/runs/$candidate_id/attempts/$attempt/jobs" \
			-F per_page=100 \
			--jq '.jobs[] | {name,steps}')
		publication_started=$(jq -s -r '
			any(.[]; any((.steps // [])[]; .name == "Build and push" and .conclusion != "skipped"))
		' <<<"$job_lines")
		if [[ "$publication_started" != "true" ]]; then
			continue
		fi
		if [[ -z "$latest" || "$attempt_started" > "$latest_started" ||
			("$attempt_started" == "$latest_started" && "$candidate_id" -gt "$latest_id") ||
			("$attempt_started" == "$latest_started" && "$candidate_id" == "$latest_id" && "$attempt" -gt "$latest_attempt") ]]; then
			latest="$candidate"
			latest_started="$attempt_started"
			latest_id="$candidate_id"
			latest_attempt="$attempt"
		fi
	done
done < <(jq -c --arg tag "$RELEASE_TAG" --arg prefix "$PUBLISH_PREFIX" --arg current_run_id "$CURRENT_RUN_ID" '
	select(
		($current_run_id == "" or (.id | tostring) != $current_run_id)
		and (
			(.event == "push" and .head_branch == $tag)
			or (.event == "workflow_dispatch" and
				(((.display_title // "") | startswith($prefix))
				or ((.display_title // "") == ("Docker Image CI " + $tag))))
		)
	)
' <<<"$run_lines")

if [[ -z "$latest" ]]; then
	echo "No previous publication-stage attempt found for $RELEASE_TAG."
	exit 0
fi

# A release-publish title records the exact tested source SHA. Direct tag
# pushes also identify their source through head_sha. Legacy dispatches with
# only the generic "Docker Image CI <tag>" title do not: head_sha identifies
# the dispatch ref, not necessarily the source_ref that was built.
latest_sha=$(jq -r --arg prefix "$PUBLISH_PREFIX" '
	if ((.display_title // "") | startswith($prefix))
	then .display_title[($prefix | length):][:40]
	elif .event == "push"
	then .head_sha
	else ""
	end
' <<<"$latest")

if [[ -z "$latest_sha" ]]; then
	if [[ "$ALLOW_TAG_REPLACEMENT" == "true" ]]; then
		echo "::warning::Explicit override enabled: $RELEASE_TAG has legacy publication history with an unknown source commit."
		jq '{id,head_sha,head_branch,display_title,status,conclusion}' <<<"$latest"
		exit 0
	fi
	echo "::error::The source commit of the legacy publication attempt for $RELEASE_TAG cannot be verified."
	echo "Its head_sha may identify the dispatch ref rather than the source_ref that was published."
	echo "Refusing to publish until explicit replacement approval is provided."
	jq '{id,head_sha,head_branch,display_title,status,conclusion}' <<<"$latest"
	exit 1
fi

if [[ "$latest_sha" == "$RELEASE_SHA" && "$REJECT_SAME_SHA_RECREATION" == "true" && "$ALLOW_TAG_REPLACEMENT" != "true" ]]; then
	echo "::error::The release tag $RELEASE_TAG already has publication history from another run."
	echo "A direct tag push must not recreate or republish an existing version, even at the same commit."
	echo "Use the Release workflow to resume or explicitly recover the publication."
	jq '{id,head_sha,head_branch,display_title,status,conclusion}' <<<"$latest"
	exit 1
fi

if [[ "$latest_sha" != "$RELEASE_SHA" ]]; then
	if [[ "$ALLOW_TAG_REPLACEMENT" == "true" ]]; then
		echo "::warning::Explicit override enabled: $RELEASE_TAG will be republished from a different commit."
		jq '{id,head_sha,head_branch,display_title,status,conclusion}' <<<"$latest"
		exit 0
	fi
	echo "::error::The latest publication attempt for $RELEASE_TAG uses another commit."
	echo "The prior attempt may have pushed an image even if its workflow did not succeed."
	echo "Refusing to replace it without explicit replacement approval."
	jq '{id,head_sha,head_branch,display_title,status,conclusion}' <<<"$latest"
	exit 1
fi

echo "Latest publication attempt matches $RELEASE_SHA; retry is safe."
