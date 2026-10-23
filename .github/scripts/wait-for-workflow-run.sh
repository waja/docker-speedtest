#!/usr/bin/env bash
# .github/scripts/wait-for-workflow-run.sh
# Wait for an existing run ID or a newly dispatched run with the given title.
set -euo pipefail

API="${1:?API path required, e.g. repos/owner/repo}"
RUN_ID="${2:-}"
DISPLAY_TITLE="${3:?Workflow run title required}"
DISPATCHED_AT="${4:-}"
TIMEOUT_SECONDS="${5:-5400}"
deadline=$((SECONDS + TIMEOUT_SECONDS))

while (( SECONDS < deadline )); do
  if [[ -n "$RUN_ID" ]]; then
    run=$(gh api "$API/actions/runs/$RUN_ID")
  else
    run_lines=$(gh api --paginate --method GET \
      "$API/actions/workflows/docker.image.yml/runs" \
      -f event=workflow_dispatch -F per_page=100 \
      --jq '.workflow_runs[] |
        {id,event,display_title,status,conclusion,created_at,html_url}')
    run=$(jq -s -c --arg title "$DISPLAY_TITLE" \
      --arg since "$DISPATCHED_AT" '
        [.[] | select(.display_title == $title
          and .created_at >= $since)]
        | sort_by(.created_at) | last // empty
      ' <<< "$run_lines")
  fi

  if [[ -n "$run" && "$run" != "null" ]]; then
    status=$(jq -r '.status' <<< "$run")
    conclusion=$(jq -r '.conclusion // empty' <<< "$run")
    run_id=$(jq -r '.id' <<< "$run")
    run_url=$(jq -r '.html_url // empty' <<< "$run")

    if [[ "$status" == "completed" ]]; then
      if [[ "$conclusion" != "success" ]]; then
        echo "::error::Workflow run $run_id ended: $conclusion"
        echo "$run_url"
        exit 1
      fi
      echo "Workflow run $run_id succeeded."
      echo "$run_url"
      exit 0
    fi
    echo "Waiting for workflow run $run_id ($status)."
  else
    echo "Waiting for workflow run $DISPLAY_TITLE."
  fi
  sleep 30
done

echo "::error::Timed out waiting for $DISPLAY_TITLE."
exit 1
