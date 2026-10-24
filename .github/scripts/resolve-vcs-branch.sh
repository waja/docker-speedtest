#!/usr/bin/env bash
# Shared helper used by docker.image.yml to resolve branch provenance.
# Print the branch name for the checked-out source, or empty for tags/commits.
set -euo pipefail

source_ref="${SOURCE_REF_INPUT:-}"
head_ref="${HEAD_REF_INPUT:-}"
github_ref="${GITHUB_REF:-}"
checked_out_sha="$(git rev-parse HEAD)"

# Explicit fully qualified refs establish their requested type.
case "$source_ref" in
refs/heads/*)
	branch="${source_ref#refs/heads/}"
	if git show-ref --verify --quiet "refs/remotes/origin/$branch" &&
		[[ "$(git rev-parse "refs/remotes/origin/$branch")" == "$checked_out_sha" ]]; then
		printf '%s\n' "$branch"
	else
		printf '\n'
	fi
	exit 0
	;;
refs/remotes/origin/*)
	branch="${source_ref#refs/remotes/origin/}"
	if git show-ref --verify --quiet "$source_ref" &&
		[[ "$(git rev-parse "$source_ref")" == "$checked_out_sha" ]]; then
		printf '%s\n' "$branch"
	else
		printf '\n'
	fi
	exit 0
	;;
refs/tags/*)
	printf '\n'
	exit 0
	;;
refs/*)
	printf '\n'
	exit 0
	;;
esac

if [[ -n "$source_ref" ]]; then
	# Match the checked-out commit to the requested branch ref.
	for ref in "refs/remotes/origin/$source_ref" "refs/heads/$source_ref"; do
		if git show-ref --verify --quiet "$ref" &&
			[[ "$(git rev-parse "$ref")" == "$checked_out_sha" ]]; then
			printf '%s\n' "$source_ref"
			exit 0
		fi
	done
	printf '\n'
	exit 0
fi

case "$github_ref" in
refs/heads/*)
	branch="${github_ref#refs/heads/}"
	if git show-ref --verify --quiet "refs/remotes/origin/$branch" &&
		[[ "$(git rev-parse "refs/remotes/origin/$branch")" == "$checked_out_sha" ]]; then
		printf '%s\n' "$branch"
	else
		printf '\n'
	fi
	;;
refs/tags/*)
	printf '\n'
	;;
*)
	# PR merge commits need the source branch supplied by GitHub.
	printf '%s\n' "$head_ref"
	;;
esac
