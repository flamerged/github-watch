#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
PLUGIN="$ROOT/bin/github-watch.5m.sh"

zsh -n "$PLUGIN"
zsh -n "$ROOT/scripts/install-swiftbar.sh"
zsh -n "$ROOT/scripts/install-dev-swiftbar.sh"
bash -n "$ROOT/scripts/auto-release.sh"

for tag in \
  '<xbar.title>' \
  '<xbar.version>' \
  '<xbar.author>' \
  '<xbar.author.github>' \
  '<xbar.desc>' \
  '<xbar.dependencies>' \
  '<xbar.abouturl>' \
  '<swiftbar.title>'; do
  grep -q "$tag" "$PLUGIN"
done

for var in \
  'GITHUBWATCH_CONFIG_FILE' \
  'GITHUBWATCH_GH_HOST' \
  'GITHUBWATCH_CACHE_FILE' \
  'GITHUBWATCH_CACHE_TTL_SECONDS' \
  'GITHUBWATCH_CLOSED_DAYS' \
  'GITHUBWATCH_STALE_DAYS' \
  'GITHUBWATCH_MAX_OPEN_PRS' \
  'GITHUBWATCH_MAX_OPEN_ISSUES' \
  'GITHUBWATCH_MAX_CLOSED_ITEMS' \
  'GITHUBWATCH_PR_SEARCH' \
  'GITHUBWATCH_ASSIGNED_PR_SEARCH' \
  'GITHUBWATCH_REVIEW_REQUESTED_PR_SEARCH' \
  'GITHUBWATCH_ISSUE_SEARCH' \
  'GITHUBWATCH_ASSIGNED_ISSUE_SEARCH' \
  'GITHUBWATCH_MENTIONED_ISSUE_SEARCH' \
  'GITHUBWATCH_SUBSCRIBED_ISSUE_SEARCH' \
  'GITHUBWATCH_CLOSED_PR_SEARCH' \
  'GITHUBWATCH_CLOSED_ISSUE_SEARCH' \
  'GITHUBWATCH_REPO_DIR' \
  'GITHUBWATCH_REPO_URL' \
  'GITHUBWATCH_RELEASE_ASSET_URL' \
  'GITHUBWATCH_UPDATE_LOG' \
  'GITHUBWATCH_CHECK_RELEASE_UPDATES' \
  'GITHUBWATCH_RELEASE_CHECK_TTL_SECONDS' \
  'GITHUBWATCH_RELEASE_CHECK_CACHE'; do
  grep -q "<xbar.var>.*$var" "$PLUGIN"
done

config_file="$(mktemp)"
cache_file="$(mktemp)"
output="$(
  GITHUBWATCH_CONFIG_FILE="$config_file" \
  GITHUBWATCH_CACHE_FILE="$cache_file" \
  GITHUBWATCH_DISABLE_GH=1 \
  GITHUBWATCH_CHECK_RELEASE_UPDATES=0 \
  "$PLUGIN"
)"

print -r -- "$output" | grep -q '^GH setup needed'
print -r -- "$output" | grep -q '^GitHub Watch$'
print -r -- "$output" | grep -q 'Open config file'
print -r -- "$output" | grep -q 'Open project page'

sample_cache="$(mktemp)"
cat > "$sample_cache" <<'JSON'
{
  "updatedAt": "2026-05-15T00:00:00Z",
  "login": "octocat",
  "host": "github.com",
  "queries": {
    "openPrs": "is:pr is:open author:octocat archived:false",
    "openIssues": "is:issue is:open author:octocat archived:false",
    "closedPrs": "is:pr author:octocat closed:>=2026-05-01",
    "closedIssues": "is:issue author:octocat closed:>=2026-05-01"
  },
  "openPrs": [
    {
      "repository": {"nameWithOwner": "acme/private-app", "isPrivate": true},
      "number": 12,
      "title": "Fix deploy pipeline",
      "url": "https://github.com/acme/private-app/pull/12",
      "isDraft": false,
      "mergeable": "CONFLICTING",
      "mergeStateStatus": "DIRTY",
      "reviewDecision": "REVIEW_REQUIRED",
      "statusCheckRollup": {"state": "FAILURE"},
      "createdAt": "2026-05-01T00:00:00Z",
      "updatedAt": "2026-05-10T00:00:00Z",
      "labels": {"nodes": [{"name": "bug"}]},
      "comments": {"totalCount": 3}
    }
  ],
  "assignedPrs": [],
  "reviewRequestedPrs": [],
  "openIssues": [
    {
      "repository": {"nameWithOwner": "oss/tooling", "isPrivate": false},
      "number": 4,
      "title": "Document auth setup",
      "url": "https://github.com/oss/tooling/issues/4",
      "createdAt": "2026-05-01T00:00:00Z",
      "updatedAt": "2026-05-14T00:00:00Z",
      "labels": {"nodes": [{"name": "docs"}]},
      "comments": {"totalCount": 1}
    }
  ],
  "assignedIssues": [],
  "mentionedIssues": [],
  "subscribedIssues": [],
  "closedPrs": [
    {
      "repository": {"nameWithOwner": "oss/tooling", "isPrivate": false},
      "number": 3,
      "title": "Add cache",
      "url": "https://github.com/oss/tooling/pull/3",
      "closedAt": "2026-05-12T00:00:00Z",
      "mergedAt": "2026-05-12T00:00:00Z"
    }
  ],
  "closedIssues": [
    {
      "repository": {"nameWithOwner": "oss/tooling", "isPrivate": false},
      "number": 2,
      "title": "Old request",
      "url": "https://github.com/oss/tooling/issues/2",
      "closedAt": "2026-05-11T00:00:00Z",
      "stateReason": "NOT_PLANNED"
    }
  ]
}
JSON

sample_output="$(
  GITHUBWATCH_CONFIG_FILE="$config_file" \
  GITHUBWATCH_CACHE_FILE="$sample_cache" \
  GITHUBWATCH_DISABLE_GH=1 \
  GITHUBWATCH_CHECK_RELEASE_UPDATES=0 \
  "$PLUGIN"
)"

print -r -- "$sample_output" | grep -q '^GH 1 PR / 1 issue / 1 attention'
print -r -- "$sample_output" | grep -q 'merge conflict'
print -r -- "$sample_output" | grep -q '^Open Review Requests$'
print -r -- "$sample_output" | grep -q '^Subscribed / Involving Issues$'
print -r -- "$sample_output" | grep -q '^Recently Closed$'

print "checks passed"
