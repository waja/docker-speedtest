# Shared helper sourced via bash by docker.image.yml.
# Print the branch name for the checked-out source, or an empty string when
# the requested ref is a tag or commit rather than a branch.
set -euo pipefail

source_ref="${SOURCE_REF_INPUT:-}"
head_ref="${HEAD_REF_INPUT:-}"
github_ref="${GITHUB_REF:-}"

case "$source_ref" in
refs/heads/*)
	printf '%s\n' "${source_ref#refs/heads/}"
	exit 0
	;;
refs/remotes/origin/*)
	printf '%s\n' "${source_ref#refs/remotes/origin/}"
	exit 0
	;;
refs/tags/*)
	printf '\n'
	exit 0
	;;
refs/*)
	# Other fully qualified refs do not establish branch provenance.
	printf '\n'
	exit 0
	;;
esac

if [[ -n "$source_ref" ]]; then
	# Resolve short refs using the local refs available to this checkout.
	if git show-ref --verify --quiet "refs/remotes/origin/$source_ref" ||
		git show-ref --verify --quiet "refs/heads/$source_ref"; then
		printf '%s\n' "$source_ref"
	else
		printf '\n'
	fi
	exit 0
fi

case "$github_ref" in
refs/heads/*)
	printf '%s\n' "${github_ref#refs/heads/}"
	;;
refs/tags/*)
	printf '\n'
	;;
*)
	# Pull requests expose their source branch through github.head_ref.
	printf '%s\n' "$head_ref"
	;;
esac
