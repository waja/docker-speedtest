#!/usr/bin/env bash
# .github/scripts/list-published-release-versions.sh
# List release versions whose image publication step was reached in any attempt.
set -euo pipefail

API="${1:?API path required, e.g. repos/owner/repo}"
release_tag_pattern='^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}$'

run_lines=$(gh api --paginate --method GET \
	"$API/actions/workflows/docker.image.yml/runs" \
	-F per_page=100 \
	--jq '.workflow_runs[] | {id,run_attempt,event,head_branch,display_title}')

while IFS= read -r candidate; do
	candidate_id=$(jq -r '.id' <<<"$candidate")
	max_attempt=$(jq -r '.run_attempt // 1' <<<"$candidate")
	if [[ $(jq -r '.event' <<<"$candidate") == "push" ]]; then
		release_tag=$(jq -r '.head_branch // empty' <<<"$candidate")
	else
		release_tag=$(jq -r '
			.display_title
			| if startswith("Docker Image CI release-publish-")
				then capture("^Docker Image CI release-publish-(?<tag>[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}-[0-9]{1,3})-").tag
				else capture("^Docker Image CI (?<tag>[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}-[0-9]{1,3})$").tag
				end
		' <<<"$candidate")
	fi
	if [[ ! "$release_tag" =~ $release_tag_pattern ]]; then
		continue
	fi
	for ((attempt = 1; attempt <= max_attempt; attempt++)); do
		job_lines=$(gh api --paginate --method GET \
			"$API/actions/runs/$candidate_id/attempts/$attempt/jobs" \
			-F per_page=100 \
			--jq '.jobs[] | {name,steps}')
		publication_started=$(jq -s -r '
			any(.[]; any((.steps // [])[]; .name == "Build and push" and .status == "completed" and .conclusion != "skipped"))
		' <<<"$job_lines")
		if [[ "$publication_started" == "true" ]]; then
			printf '%s\n' "$release_tag"
			break
		fi
	done
done < <(jq -c --arg pattern "^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}-[0-9]{1,3}$" --arg title_pattern "^Docker Image CI release-publish-[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}-[0-9]{1,3}-" '
	select(
		(.event == "push" and ((.head_branch // "") | test($pattern)))
		or (.event == "workflow_dispatch" and
			((.display_title // "") | (test($title_pattern)
			or test("^Docker Image CI [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}-[0-9]{1,3}$"))))
	)
' <<<"$run_lines")
