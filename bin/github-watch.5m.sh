#!/bin/zsh
# <xbar.title>GitHub Watch</xbar.title>
# <xbar.version>v0.1.0</xbar.version> # x-release-please-version
# <xbar.author>flamerged</xbar.author>
# <xbar.author.github>flamerged</xbar.author.github>
# <xbar.desc>Tracks your open GitHub pull requests, issues, health signals, and recently closed work across repositories.</xbar.desc>
# <xbar.dependencies>zsh, gh, jq, curl</xbar.dependencies>
# <xbar.abouturl>https://github.com/flamerged/github-watch</xbar.abouturl>
# <xbar.var>string(GITHUBWATCH_CONFIG_FILE="~/.config/github-watch/config.env"): GitHub Watch config file path</xbar.var>
# <xbar.var>string(GITHUBWATCH_GH_HOST="github.com"): GitHub host used by gh</xbar.var>
# <xbar.var>string(GITHUBWATCH_CACHE_FILE="~/.cache/github-watch/inventory.json"): Cached GitHub inventory JSON path</xbar.var>
# <xbar.var>string(GITHUBWATCH_CACHE_TTL_SECONDS="600"): Seconds between automatic GitHub inventory refreshes</xbar.var>
# <xbar.var>string(GITHUBWATCH_CLOSED_DAYS="14"): Days of recently closed PRs and issues to show</xbar.var>
# <xbar.var>string(GITHUBWATCH_STALE_DAYS="14"): Days without updates before open items are marked stale</xbar.var>
# <xbar.var>string(GITHUBWATCH_MAX_OPEN_PRS="30"): Maximum open PRs to fetch and render</xbar.var>
# <xbar.var>string(GITHUBWATCH_MAX_OPEN_ISSUES="30"): Maximum open issues to fetch and render</xbar.var>
# <xbar.var>string(GITHUBWATCH_MAX_CLOSED_ITEMS="10"): Maximum recently closed PRs and issues to fetch and render</xbar.var>
# <xbar.var>string(GITHUBWATCH_PR_SEARCH="is:pr is:open author:{login} archived:false sort:updated-desc"): Open PR search template</xbar.var>
# <xbar.var>string(GITHUBWATCH_ASSIGNED_PR_SEARCH="is:pr is:open assignee:{login} archived:false sort:updated-desc"): Assigned PR search template</xbar.var>
# <xbar.var>string(GITHUBWATCH_REVIEW_REQUESTED_PR_SEARCH="is:pr is:open review-requested:{login} archived:false sort:updated-desc"): Review-requested PR search template</xbar.var>
# <xbar.var>string(GITHUBWATCH_ISSUE_SEARCH="is:issue is:open author:{login} archived:false sort:updated-desc"): Open issue search template</xbar.var>
# <xbar.var>string(GITHUBWATCH_ASSIGNED_ISSUE_SEARCH="is:issue is:open assignee:{login} archived:false sort:updated-desc"): Assigned issue search template</xbar.var>
# <xbar.var>string(GITHUBWATCH_MENTIONED_ISSUE_SEARCH="is:issue is:open mentions:{login} archived:false sort:updated-desc"): Mentioned issue search template</xbar.var>
# <xbar.var>string(GITHUBWATCH_SUBSCRIBED_ISSUE_SEARCH="is:issue is:open involves:{login} -author:{login} -assignee:{login} -mentions:{login} archived:false sort:updated-desc"): Involved or subscribed issue search template</xbar.var>
# <xbar.var>string(GITHUBWATCH_CLOSED_PR_SEARCH="is:pr author:{login} archived:false closed:>={since} sort:updated-desc"): Recently closed PR search template</xbar.var>
# <xbar.var>string(GITHUBWATCH_CLOSED_ISSUE_SEARCH="is:issue author:{login} archived:false closed:>={since} sort:updated-desc"): Recently closed issue search template</xbar.var>
# <xbar.var>boolean(GITHUBWATCH_SHOW_PRIVATE_BADGE=true): Mark private repositories in menu rows</xbar.var>
# <xbar.var>string(GITHUBWATCH_REPO_DIR=""): Optional GitHub Watch git checkout for source metadata</xbar.var>
# <xbar.var>string(GITHUBWATCH_REPO_URL="https://github.com/flamerged/github-watch"): GitHub Watch repository URL</xbar.var>
# <xbar.var>string(GITHUBWATCH_RELEASE_ASSET_URL="https://github.com/flamerged/github-watch/releases/latest/download/github-watch.5m.sh"): Latest release asset URL for copied-plugin updates</xbar.var>
# <xbar.var>string(GITHUBWATCH_UPDATE_LOG="~/.cache/github-watch/update.log"): Update log file path</xbar.var>
# <xbar.var>boolean(GITHUBWATCH_CHECK_RELEASE_UPDATES=true): Check latest GitHub Watch release in the background</xbar.var>
# <xbar.var>string(GITHUBWATCH_RELEASE_CHECK_TTL_SECONDS="86400"): Seconds between latest-release checks when enabled</xbar.var>
# <xbar.var>string(GITHUBWATCH_RELEASE_CHECK_CACHE="~/.cache/github-watch/release-check.tsv"): Latest-release check cache path</xbar.var>
# <swiftbar.title>GitHub Watch</swiftbar.title>
# <swiftbar.version>v0.1.0</swiftbar.version> # x-release-please-version
# <swiftbar.author>flamerged</swiftbar.author>
# <swiftbar.desc>Tracks your open GitHub pull requests, issues, health signals, and recently closed work across repositories.</swiftbar.desc>
# <swiftbar.refresh>5m</swiftbar.refresh>

set -u

PLUGIN_VERSION="0.1.0" # x-release-please-version
PLUGIN_PATH="${0:A}"
PLUGIN_DIR="${PLUGIN_PATH:h}"
CONFIG_FILE="${GITHUBWATCH_CONFIG_FILE:-$HOME/.config/github-watch/config.env}"
CONFIG_FILE="${CONFIG_FILE/#\~/$HOME}"

export PATH="/opt/homebrew/bin:/usr/local/bin:${HOME}/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

emit() {
  builtin print -r -- "$@"
}

print() {
  builtin print -r -- "$@"
}

trim_space() {
  local value="${1:-}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  builtin print -r -- "$value"
}

load_config_file() {
  [[ -f "$CONFIG_FILE" ]] || return
  local line key value
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    line="$(trim_space "$line")"
    [[ -z "$line" || "$line" == \#* ]] && continue
    if [[ "$line" == export[[:space:]]* ]]; then
      line="$(trim_space "${line#export}")"
    fi
    [[ "$line" == *"="* ]] || continue
    key="$(trim_space "${line%%=*}")"
    value="$(trim_space "${line#*=}")"
    [[ "$key" == GITHUBWATCH_[A-Z0-9_]* ]] || continue
    printenv "$key" >/dev/null 2>&1 && continue
    if [[ "$value" == \"*\" && "$value" == *\" ]]; then
      value="${value[2,-2]}"
    elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
      value="${value[2,-2]}"
    fi
    export "$key=$value"
  done < "$CONFIG_FILE"
}

write_default_config() {
  mkdir -p "${CONFIG_FILE:h}" 2>/dev/null || return 1
  [[ -f "$CONFIG_FILE" ]] && return 0
  {
    builtin print -r -- "# GitHub Watch config"
    builtin print -r -- "# Use KEY=value lines. Only GITHUBWATCH_* keys are loaded."
    builtin print -r -- "# Environment variables passed by the launcher override this file."
    builtin print -r -- ""
    builtin print -r -- "# Auth is handled by gh. Run: gh auth login"
    builtin print -r -- "GITHUBWATCH_GH_HOST=github.com"
    builtin print -r -- ""
    builtin print -r -- "# Cache broad GitHub searches so normal menu refreshes are cheap."
    builtin print -r -- "GITHUBWATCH_CACHE_TTL_SECONDS=600"
    builtin print -r -- "GITHUBWATCH_CLOSED_DAYS=14"
    builtin print -r -- "GITHUBWATCH_STALE_DAYS=14"
    builtin print -r -- ""
    builtin print -r -- "# Change author:{login} to involves:{login}, assignee:{login}, or review-requested:{login}"
    builtin print -r -- "# if you want broader scope."
    builtin print -r -- "GITHUBWATCH_PR_SEARCH=\"is:pr is:open author:{login} archived:false sort:updated-desc\""
    builtin print -r -- "GITHUBWATCH_ASSIGNED_PR_SEARCH=\"is:pr is:open assignee:{login} archived:false sort:updated-desc\""
    builtin print -r -- "GITHUBWATCH_REVIEW_REQUESTED_PR_SEARCH=\"is:pr is:open review-requested:{login} archived:false sort:updated-desc\""
    builtin print -r -- "GITHUBWATCH_ISSUE_SEARCH=\"is:issue is:open author:{login} archived:false sort:updated-desc\""
    builtin print -r -- "GITHUBWATCH_ASSIGNED_ISSUE_SEARCH=\"is:issue is:open assignee:{login} archived:false sort:updated-desc\""
    builtin print -r -- "GITHUBWATCH_MENTIONED_ISSUE_SEARCH=\"is:issue is:open mentions:{login} archived:false sort:updated-desc\""
    builtin print -r -- "GITHUBWATCH_SUBSCRIBED_ISSUE_SEARCH=\"is:issue is:open involves:{login} -author:{login} -assignee:{login} -mentions:{login} archived:false sort:updated-desc\""
    builtin print -r -- "GITHUBWATCH_CLOSED_PR_SEARCH=\"is:pr author:{login} archived:false closed:>={since} sort:updated-desc\""
    builtin print -r -- "GITHUBWATCH_CLOSED_ISSUE_SEARCH=\"is:issue author:{login} archived:false closed:>={since} sort:updated-desc\""
  } > "$CONFIG_FILE"
}

load_config_file

GH="${GITHUBWATCH_GH:-$(command -v gh 2>/dev/null || true)}"
JQ="${GITHUBWATCH_JQ:-$(command -v jq 2>/dev/null || true)}"
CURL="${GITHUBWATCH_CURL:-$(command -v curl 2>/dev/null || true)}"
SED="${GITHUBWATCH_SED:-$(command -v sed 2>/dev/null || true)}"

GH_HOST="${GITHUBWATCH_GH_HOST:-github.com}"
CACHE_FILE="${GITHUBWATCH_CACHE_FILE:-$HOME/.cache/github-watch/inventory.json}"
CACHE_FILE="${CACHE_FILE/#\~/$HOME}"
CACHE_ERROR="${CACHE_FILE}.error"
CACHE_TTL_SECONDS="${GITHUBWATCH_CACHE_TTL_SECONDS:-600}"
CLOSED_DAYS="${GITHUBWATCH_CLOSED_DAYS:-14}"
STALE_DAYS="${GITHUBWATCH_STALE_DAYS:-14}"
MAX_OPEN_PRS="${GITHUBWATCH_MAX_OPEN_PRS:-30}"
MAX_OPEN_ISSUES="${GITHUBWATCH_MAX_OPEN_ISSUES:-30}"
MAX_CLOSED_ITEMS="${GITHUBWATCH_MAX_CLOSED_ITEMS:-10}"
SHOW_PRIVATE_BADGE="${GITHUBWATCH_SHOW_PRIVATE_BADGE:-1}"
GITHUBWATCH_REPO_DIR="${GITHUBWATCH_REPO_DIR:-}"
GITHUBWATCH_REPO_URL="${GITHUBWATCH_REPO_URL:-https://github.com/flamerged/github-watch}"
RELEASE_ASSET_URL="${GITHUBWATCH_RELEASE_ASSET_URL:-https://github.com/flamerged/github-watch/releases/latest/download/github-watch.5m.sh}"
UPDATE_LOG="${GITHUBWATCH_UPDATE_LOG:-$HOME/.cache/github-watch/update.log}"
UPDATE_LOG="${UPDATE_LOG/#\~/$HOME}"
CHECK_RELEASE_UPDATES="${GITHUBWATCH_CHECK_RELEASE_UPDATES:-1}"
RELEASE_CHECK_TTL_SECONDS="${GITHUBWATCH_RELEASE_CHECK_TTL_SECONDS:-86400}"
RELEASE_CHECK_CACHE="${GITHUBWATCH_RELEASE_CHECK_CACHE:-$HOME/.cache/github-watch/release-check.tsv}"
RELEASE_CHECK_CACHE="${RELEASE_CHECK_CACHE/#\~/$HOME}"
DISABLE_GH="${GITHUBWATCH_DISABLE_GH:-0}"

PR_SEARCH_TEMPLATE="${GITHUBWATCH_PR_SEARCH:-is:pr is:open author:{login} archived:false sort:updated-desc}"
ASSIGNED_PR_SEARCH_TEMPLATE="${GITHUBWATCH_ASSIGNED_PR_SEARCH:-is:pr is:open assignee:{login} archived:false sort:updated-desc}"
REVIEW_REQUESTED_PR_SEARCH_TEMPLATE="${GITHUBWATCH_REVIEW_REQUESTED_PR_SEARCH:-is:pr is:open review-requested:{login} archived:false sort:updated-desc}"
ISSUE_SEARCH_TEMPLATE="${GITHUBWATCH_ISSUE_SEARCH:-is:issue is:open author:{login} archived:false sort:updated-desc}"
ASSIGNED_ISSUE_SEARCH_TEMPLATE="${GITHUBWATCH_ASSIGNED_ISSUE_SEARCH:-is:issue is:open assignee:{login} archived:false sort:updated-desc}"
MENTIONED_ISSUE_SEARCH_TEMPLATE="${GITHUBWATCH_MENTIONED_ISSUE_SEARCH:-is:issue is:open mentions:{login} archived:false sort:updated-desc}"
SUBSCRIBED_ISSUE_SEARCH_TEMPLATE="${GITHUBWATCH_SUBSCRIBED_ISSUE_SEARCH:-is:issue is:open involves:{login} -author:{login} -assignee:{login} -mentions:{login} archived:false sort:updated-desc}"
CLOSED_PR_SEARCH_TEMPLATE="${GITHUBWATCH_CLOSED_PR_SEARCH:-is:pr author:{login} archived:false closed:>={since} sort:updated-desc}"
CLOSED_ISSUE_SEARCH_TEMPLATE="${GITHUBWATCH_CLOSED_ISSUE_SEARCH:-is:issue author:{login} archived:false closed:>={since} sort:updated-desc}"

truthy() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

have() {
  [[ -n "${1:-}" && -x "$1" ]]
}

menu_text() {
  local value="${1:-}"
  value="${value//$'\r'/ }"
  value="${value//$'\n'/ }"
  value="${value//$'\t'/ }"
  value="${value//|/\/}"
  emit "$value"
}

plural() {
  [[ "${1:-0}" == "1" ]] || emit "s"
}

shorten_path() {
  local value="${1:-}"
  value="${value/#$HOME/~}"
  emit "$value"
}

open_target() {
  local target="${1:-}"
  [[ -z "$target" ]] && return 0
  if command -v open >/dev/null 2>&1; then
    open "$target" >/dev/null 2>&1 &
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$target" >/dev/null 2>&1 &
  fi
}

open_text_target() {
  local target="${1:-}"
  [[ -z "$target" ]] && return 0
  if command -v open >/dev/null 2>&1; then
    open -e "$target" >/dev/null 2>&1 &
  else
    open_target "$target"
  fi
}

file_mtime() {
  local file="$1"
  [[ -f "$file" ]] || { emit ""; return; }
  if stat -f %m "$file" >/dev/null 2>&1; then
    stat -f %m "$file"
  elif stat -c %Y "$file" >/dev/null 2>&1; then
    stat -c %Y "$file"
  fi
}

now_epoch() {
  date +%s 2>/dev/null || emit "0"
}

cache_age() {
  local mtime now
  mtime="$(file_mtime "$CACHE_FILE")"
  [[ -n "$mtime" ]] || { emit ""; return; }
  now="$(now_epoch)"
  emit $(( now - mtime ))
}

release_tag_norm() {
  local value="${1:-}"
  value="${value%%-*}"
  value="${value#v}"
  emit "$value"
}

plugin_repo_root() {
  command -v git >/dev/null 2>&1 || return
  local candidate="${GITHUBWATCH_REPO_DIR:-}"
  if [[ -n "$candidate" ]] && git -C "$candidate" rev-parse --show-toplevel >/dev/null 2>&1; then
    git -C "$candidate" rev-parse --show-toplevel 2>/dev/null
    return
  fi
  candidate="${PLUGIN_DIR:h}"
  if git -C "$candidate" rev-parse --show-toplevel >/dev/null 2>&1; then
    git -C "$candidate" rev-parse --show-toplevel 2>/dev/null
  fi
}

plugin_git_summary() {
  local root="$1" branch sha upstream counts ahead behind dirty state
  command -v git >/dev/null 2>&1 || return
  branch="$(git -C "$root" branch --show-current 2>/dev/null)"
  sha="$(git -C "$root" rev-parse --short HEAD 2>/dev/null)"
  upstream="$(git -C "$root" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"
  dirty="$(git -C "$root" status --porcelain 2>/dev/null)"
  state=""
  if [[ -n "$upstream" ]]; then
    counts="$(git -C "$root" rev-list --left-right --count HEAD..."$upstream" 2>/dev/null)"
    ahead="${counts%%[[:space:]]*}"
    behind="${counts##*[[:space:]]}"
    [[ -n "$ahead" && "$ahead" != "0" ]] && state="${state}, ${ahead} ahead"
    [[ -n "$behind" && "$behind" != "0" ]] && state="${state}, ${behind} behind"
  fi
  [[ -n "$dirty" ]] && state="${state}, dirty"
  printf '%s' "${branch:-detached} ${sha:-unknown}${state}"
}

plugin_version_label() {
  local root="${1:-}" exact desc
  if [[ -n "$root" ]] && command -v git >/dev/null 2>&1; then
    exact="$(git -C "$root" describe --tags --exact-match --match 'v[0-9]*' HEAD 2>/dev/null)"
    if [[ -n "$exact" ]]; then
      printf '%s' "$exact"
      return
    fi
    desc="$(git -C "$root" describe --tags --match 'v[0-9]*' --long --always HEAD 2>/dev/null)"
    if [[ "$desc" == v* ]]; then
      printf '%s' "$desc"
      return
    fi
  fi
  printf 'v%s' "$PLUGIN_VERSION"
}

latest_release_tag_from_asset_url() {
  local tag
  have "$SED" || return 1
  tag="$(emit "$RELEASE_ASSET_URL" | "$SED" -n 's#.*releases/download/\([^/]*\)/.*#\1#p' | head -1)"
  [[ -n "$tag" && "$tag" != "latest" ]] || return 1
  emit "$tag"
}

github_repo_slug() {
  local slug
  [[ "$GITHUBWATCH_REPO_URL" == https://github.com/* ]] || return 1
  slug="${GITHUBWATCH_REPO_URL#https://github.com/}"
  slug="${slug%%\?*}"
  slug="${slug%%#*}"
  slug="${slug%/}"
  slug="${slug%.git}"
  [[ "$slug" == */* && "$slug" != */*/* ]] || return 1
  emit "$slug"
}

latest_release_tag() {
  local repo tag
  have "$CURL" || return 1
  have "$JQ" || return 1
  if repo="$(github_repo_slug)" && [[ -n "$repo" ]]; then
    tag="$("$CURL" -fsSL \
      --connect-timeout 5 \
      --max-time 15 \
      --retry 1 \
      -H 'Accept: application/vnd.github+json' \
      "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null \
      | "$JQ" -r '.tag_name // empty' 2>/dev/null)"
    if [[ -n "$tag" && "$tag" != "null" ]]; then
      emit "$tag"
      return
    fi
  fi
  latest_release_tag_from_asset_url
}

write_release_check_cache() {
  local now tmp latest check_status rc
  now="$(now_epoch)"
  mkdir -p "${RELEASE_CHECK_CACHE:h}" 2>/dev/null || {
    rm -f "${RELEASE_CHECK_CACHE}.lock" 2>/dev/null || true
    return 1
  }
  tmp="${RELEASE_CHECK_CACHE}.$$"
  if latest="$(latest_release_tag)"; then
    check_status="ok"
  else
    check_status="error"
    latest=""
  fi
  if builtin printf '%s\t%s\t%s\n' "$now" "$check_status" "$latest" > "$tmp" \
    && mv "$tmp" "$RELEASE_CHECK_CACHE"; then
    [[ "$check_status" == "ok" ]]
    rc=$?
  else
    rm -f "$tmp" 2>/dev/null || true
    rc=1
  fi
  rm -f "${RELEASE_CHECK_CACHE}.lock" 2>/dev/null || true
  return "$rc"
}

release_check_cache_fields() {
  [[ -f "$RELEASE_CHECK_CACHE" ]] || return 1
  local ts check_status latest rest
  IFS=$'\t' read -r ts check_status latest rest < "$RELEASE_CHECK_CACHE" || return 1
  builtin printf '%s\t%s\t%s\n' "$ts" "$check_status" "$latest"
}

release_check_cache_age() {
  local mtime now
  mtime="$(file_mtime "$RELEASE_CHECK_CACHE")"
  [[ -n "$mtime" ]] || { emit ""; return; }
  now="$(now_epoch)"
  emit $(( now - mtime ))
}

maybe_refresh_release_check() {
  truthy "$CHECK_RELEASE_UPDATES" || return
  [[ "$RELEASE_CHECK_TTL_SECONDS" == <-> ]] || RELEASE_CHECK_TTL_SECONDS=86400
  local age lock_file lock_mtime current_mtime now lock_age
  age="$(release_check_cache_age)"
  if [[ -n "$age" && "$age" -le "$RELEASE_CHECK_TTL_SECONDS" ]]; then
    return
  fi
  mkdir -p "${RELEASE_CHECK_CACHE:h}" 2>/dev/null || return
  lock_file="${RELEASE_CHECK_CACHE}.lock"
  lock_mtime="$(file_mtime "$lock_file")"
  if [[ -n "$lock_mtime" ]]; then
    now="$(now_epoch)"
    lock_age=$(( now - lock_mtime ))
    if [[ "$lock_age" -gt 300 ]]; then
      current_mtime="$(file_mtime "$lock_file")"
      [[ "$current_mtime" == "$lock_mtime" ]] && rm -f "$lock_file" 2>/dev/null || true
    fi
  fi
  ( set -C; : > "$lock_file" ) 2>/dev/null || return
  "$PLUGIN_PATH" check-release >/dev/null 2>&1 &
}

release_status_label() {
  local current="$1" fields ts check_status latest
  truthy "$CHECK_RELEASE_UPDATES" || { emit "update checks disabled"; return; }
  fields="$(release_check_cache_fields)" || { emit "checking latest release"; return; }
  IFS=$'\t' read -r ts check_status latest <<< "$fields"
  if [[ "$check_status" != "ok" || -z "$latest" ]]; then
    emit "latest check unavailable"
  elif [[ "$(release_tag_norm "$latest")" == "$(release_tag_norm "$current")" ]]; then
    emit "latest"
  else
    emit "update $latest available"
  fi
}

release_status_color() {
  local label="$1"
  case "$label" in
    update\ *\ available) emit "#cc6633" ;;
    latest) emit "#2f8f46" ;;
    *) emit "#888888" ;;
  esac
}

cached_latest_release_tag() {
  local fields ts check_status latest
  fields="$(release_check_cache_fields)" || return 1
  IFS=$'\t' read -r ts check_status latest <<< "$fields"
  [[ "$check_status" == "ok" && -n "$latest" ]] || return 1
  emit "$latest"
}

log_update() {
  mkdir -p "${UPDATE_LOG:h}" 2>/dev/null || return
  builtin print -r -- "[$(date '+%Y-%m-%d %H:%M:%S %z' 2>/dev/null || date)] ${1:-}" >> "$UPDATE_LOG" 2>/dev/null || true
}

update_message() {
  local message="${1:-}"
  print "$message"
  log_update "$message"
}

update_plugin_from_release() {
  local repo_root
  mkdir -p "${UPDATE_LOG:h}" 2>/dev/null || true
  log_update "=== GitHub Watch release update started ==="
  log_update "Plugin: $PLUGIN_PATH"
  log_update "Asset: $RELEASE_ASSET_URL"

  repo_root="$(plugin_repo_root)"
  if [[ -n "$repo_root" && "$PLUGIN_PATH" == "$repo_root"/* ]]; then
    update_message "Plugin appears to be running from a git checkout: $repo_root"
    update_message "Use git commands in the checkout for development updates."
    return 1
  fi

  if ! have "$CURL"; then
    update_message "curl is required to update from the latest release."
    return 1
  fi
  if [[ ! -w "$PLUGIN_PATH" || ! -w "$PLUGIN_DIR" ]]; then
    update_message "Plugin file or directory is not writable: $PLUGIN_PATH"
    return 1
  fi
  if [[ "$RELEASE_ASSET_URL" != https://* ]]; then
    update_message "Refusing non-HTTPS release asset URL: $RELEASE_ASSET_URL"
    return 1
  fi

  local tmp first_line content curl_log
  tmp="${PLUGIN_DIR}/.github-watch.5m.sh.$$"
  curl_log="$UPDATE_LOG"
  [[ -d "${UPDATE_LOG:h}" && -w "${UPDATE_LOG:h}" ]] || curl_log="/dev/null"
  rm -f "$tmp"

  update_message "Downloading latest GitHub Watch release asset..."
  if ! "$CURL" -fsSL \
    --connect-timeout 5 \
    --max-time 30 \
    --retry 2 \
    --retry-delay 1 \
    "$RELEASE_ASSET_URL" -o "$tmp" >> "$curl_log" 2>&1; then
    rm -f "$tmp"
    update_message "Download failed: $RELEASE_ASSET_URL"
    return 1
  fi

  IFS= read -r first_line < "$tmp" || first_line=""
  content="$(< "$tmp")"
  if [[ "$first_line" != "#!/bin/zsh" || "$content" != *"<xbar.title>GitHub Watch</xbar.title>"* || "$content" != *"PLUGIN_VERSION=\""* ]]; then
    rm -f "$tmp"
    update_message "Downloaded file did not look like a GitHub Watch plugin."
    return 1
  fi

  chmod +x "$tmp" || {
    rm -f "$tmp"
    update_message "Could not mark downloaded plugin executable."
    return 1
  }
  mv "$tmp" "$PLUGIN_PATH" || {
    rm -f "$tmp"
    update_message "Could not replace plugin file: $PLUGIN_PATH"
    return 1
  }
  update_message "Updated GitHub Watch from the latest release."
}

gh_api() {
  if [[ "$GH_HOST" == "github.com" ]]; then
    "$GH" api "$@"
  else
    "$GH" api --hostname "$GH_HOST" "$@"
  fi
}

gh_auth_status() {
  if [[ "$GH_HOST" == "github.com" ]]; then
    "$GH" auth status >/dev/null 2>&1
  else
    "$GH" auth status --hostname "$GH_HOST" >/dev/null 2>&1
  fi
}

closed_since_date() {
  local days="${1:-14}"
  [[ "$days" == <-> ]] || days=14
  if date -u -v-"${days}"d +%Y-%m-%d >/dev/null 2>&1; then
    date -u -v-"${days}"d +%Y-%m-%d
  else
    date -u -d "${days} days ago" +%Y-%m-%d 2>/dev/null || date -u +%Y-%m-%d
  fi
}

render_template() {
  local value="$1" login="$2" since="$3"
  value="${value//\{login\}/$login}"
  value="${value//\{since\}/$since}"
  emit "$value"
}

pr_graphql_query() {
  cat <<'GRAPHQL'
query($searchQuery: String!, $first: Int!) {
  search(type: ISSUE, query: $searchQuery, first: $first) {
    issueCount
    nodes {
      ... on PullRequest {
        repository { nameWithOwner isPrivate }
        number
        title
        url
        state
        isDraft
        mergeable
        mergeStateStatus
        reviewDecision
        createdAt
        updatedAt
        closedAt
        mergedAt
        comments { totalCount }
        labels(first: 5) { nodes { name } }
        statusCheckRollup { state }
      }
    }
  }
}
GRAPHQL
}

issue_graphql_query() {
  cat <<'GRAPHQL'
query($searchQuery: String!, $first: Int!) {
  search(type: ISSUE, query: $searchQuery, first: $first) {
    issueCount
    nodes {
      ... on Issue {
        repository { nameWithOwner isPrivate }
        number
        title
        url
        state
        stateReason
        createdAt
        updatedAt
        closedAt
        comments { totalCount }
        labels(first: 5) { nodes { name } }
      }
    }
  }
}
GRAPHQL
}

write_cache_error() {
  mkdir -p "${CACHE_ERROR:h}" 2>/dev/null || return
  builtin print -r -- "[$(date '+%Y-%m-%d %H:%M:%S %z' 2>/dev/null || date)] ${1:-unknown error}" > "$CACHE_ERROR" 2>/dev/null || true
}

run_graphql() {
  local query="$1" search_query="$2" first="$3"
  gh_api graphql -f query="$query" -F searchQuery="$search_query" -F first="$first"
}

write_inventory_cache() {
  truthy "$DISABLE_GH" && {
    write_cache_error "GitHub calls are disabled by GITHUBWATCH_DISABLE_GH."
    rm -f "${CACHE_FILE}.lock" 2>/dev/null || true
    return 1
  }
  have "$GH" || {
    write_cache_error "gh is required. Install it with: brew install gh"
    rm -f "${CACHE_FILE}.lock" 2>/dev/null || true
    return 1
  }
  have "$JQ" || {
    write_cache_error "jq is required. Install it with: brew install jq"
    rm -f "${CACHE_FILE}.lock" 2>/dev/null || true
    return 1
  }
  gh_auth_status || {
    write_cache_error "gh is not authenticated for ${GH_HOST}. Run: gh auth login"
    rm -f "${CACHE_FILE}.lock" 2>/dev/null || true
    return 1
  }

  local login since open_pr_query assigned_pr_query review_requested_pr_query open_issue_query assigned_issue_query mentioned_issue_query subscribed_issue_query closed_pr_query closed_issue_query tmpdir errfile now_iso tmp_cache
  login="$(gh_api /user --jq '.login' 2>/dev/null)" || {
    write_cache_error "Could not read authenticated GitHub login with gh api /user."
    rm -f "${CACHE_FILE}.lock" 2>/dev/null || true
    return 1
  }
  since="$(closed_since_date "$CLOSED_DAYS")"
  open_pr_query="$(render_template "$PR_SEARCH_TEMPLATE" "$login" "$since")"
  assigned_pr_query="$(render_template "$ASSIGNED_PR_SEARCH_TEMPLATE" "$login" "$since")"
  review_requested_pr_query="$(render_template "$REVIEW_REQUESTED_PR_SEARCH_TEMPLATE" "$login" "$since")"
  open_issue_query="$(render_template "$ISSUE_SEARCH_TEMPLATE" "$login" "$since")"
  assigned_issue_query="$(render_template "$ASSIGNED_ISSUE_SEARCH_TEMPLATE" "$login" "$since")"
  mentioned_issue_query="$(render_template "$MENTIONED_ISSUE_SEARCH_TEMPLATE" "$login" "$since")"
  subscribed_issue_query="$(render_template "$SUBSCRIBED_ISSUE_SEARCH_TEMPLATE" "$login" "$since")"
  closed_pr_query="$(render_template "$CLOSED_PR_SEARCH_TEMPLATE" "$login" "$since")"
  closed_issue_query="$(render_template "$CLOSED_ISSUE_SEARCH_TEMPLATE" "$login" "$since")"

  tmpdir="$(mktemp -d)"
  errfile="$tmpdir/error.log"

  if ! run_graphql "$(pr_graphql_query)" "$open_pr_query" "$MAX_OPEN_PRS" > "$tmpdir/open-prs.json" 2> "$errfile"; then
    write_cache_error "Open PR query failed: $(head -1 "$errfile" 2>/dev/null)"
    rm -rf "$tmpdir"
    rm -f "${CACHE_FILE}.lock" 2>/dev/null || true
    return 1
  fi
  if ! run_graphql "$(pr_graphql_query)" "$assigned_pr_query" "$MAX_OPEN_PRS" > "$tmpdir/assigned-prs.json" 2> "$errfile"; then
    write_cache_error "Assigned PR query failed: $(head -1 "$errfile" 2>/dev/null)"
    rm -rf "$tmpdir"
    rm -f "${CACHE_FILE}.lock" 2>/dev/null || true
    return 1
  fi
  if ! run_graphql "$(pr_graphql_query)" "$review_requested_pr_query" "$MAX_OPEN_PRS" > "$tmpdir/review-requested-prs.json" 2> "$errfile"; then
    write_cache_error "Review-requested PR query failed: $(head -1 "$errfile" 2>/dev/null)"
    rm -rf "$tmpdir"
    rm -f "${CACHE_FILE}.lock" 2>/dev/null || true
    return 1
  fi
  if ! run_graphql "$(issue_graphql_query)" "$open_issue_query" "$MAX_OPEN_ISSUES" > "$tmpdir/open-issues.json" 2> "$errfile"; then
    write_cache_error "Open issue query failed: $(head -1 "$errfile" 2>/dev/null)"
    rm -rf "$tmpdir"
    rm -f "${CACHE_FILE}.lock" 2>/dev/null || true
    return 1
  fi
  if ! run_graphql "$(issue_graphql_query)" "$assigned_issue_query" "$MAX_OPEN_ISSUES" > "$tmpdir/assigned-issues.json" 2> "$errfile"; then
    write_cache_error "Assigned issue query failed: $(head -1 "$errfile" 2>/dev/null)"
    rm -rf "$tmpdir"
    rm -f "${CACHE_FILE}.lock" 2>/dev/null || true
    return 1
  fi
  if ! run_graphql "$(issue_graphql_query)" "$mentioned_issue_query" "$MAX_OPEN_ISSUES" > "$tmpdir/mentioned-issues.json" 2> "$errfile"; then
    write_cache_error "Mentioned issue query failed: $(head -1 "$errfile" 2>/dev/null)"
    rm -rf "$tmpdir"
    rm -f "${CACHE_FILE}.lock" 2>/dev/null || true
    return 1
  fi
  if ! run_graphql "$(issue_graphql_query)" "$subscribed_issue_query" "$MAX_OPEN_ISSUES" > "$tmpdir/subscribed-issues.json" 2> "$errfile"; then
    write_cache_error "Subscribed issue query failed: $(head -1 "$errfile" 2>/dev/null)"
    rm -rf "$tmpdir"
    rm -f "${CACHE_FILE}.lock" 2>/dev/null || true
    return 1
  fi
  if ! run_graphql "$(pr_graphql_query)" "$closed_pr_query" "$MAX_CLOSED_ITEMS" > "$tmpdir/closed-prs.json" 2> "$errfile"; then
    write_cache_error "Closed PR query failed: $(head -1 "$errfile" 2>/dev/null)"
    rm -rf "$tmpdir"
    rm -f "${CACHE_FILE}.lock" 2>/dev/null || true
    return 1
  fi
  if ! run_graphql "$(issue_graphql_query)" "$closed_issue_query" "$MAX_CLOSED_ITEMS" > "$tmpdir/closed-issues.json" 2> "$errfile"; then
    write_cache_error "Closed issue query failed: $(head -1 "$errfile" 2>/dev/null)"
    rm -rf "$tmpdir"
    rm -f "${CACHE_FILE}.lock" 2>/dev/null || true
    return 1
  fi

  now_iso="$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%SZ')"
  mkdir -p "${CACHE_FILE:h}" 2>/dev/null || {
    write_cache_error "Could not create cache directory: ${CACHE_FILE:h}"
    rm -rf "$tmpdir"
    rm -f "${CACHE_FILE}.lock" 2>/dev/null || true
    return 1
  }
  tmp_cache="${CACHE_FILE}.$$"
  if "$JQ" -n \
    --arg updatedAt "$now_iso" \
    --arg login "$login" \
    --arg host "$GH_HOST" \
    --arg openPrsQuery "$open_pr_query" \
    --arg assignedPrsQuery "$assigned_pr_query" \
    --arg reviewRequestedPrsQuery "$review_requested_pr_query" \
    --arg openIssuesQuery "$open_issue_query" \
    --arg assignedIssuesQuery "$assigned_issue_query" \
    --arg mentionedIssuesQuery "$mentioned_issue_query" \
    --arg subscribedIssuesQuery "$subscribed_issue_query" \
    --arg closedPrsQuery "$closed_pr_query" \
    --arg closedIssuesQuery "$closed_issue_query" \
    --slurpfile openPrs "$tmpdir/open-prs.json" \
    --slurpfile assignedPrs "$tmpdir/assigned-prs.json" \
    --slurpfile reviewRequestedPrs "$tmpdir/review-requested-prs.json" \
    --slurpfile openIssues "$tmpdir/open-issues.json" \
    --slurpfile assignedIssues "$tmpdir/assigned-issues.json" \
    --slurpfile mentionedIssues "$tmpdir/mentioned-issues.json" \
    --slurpfile subscribedIssues "$tmpdir/subscribed-issues.json" \
    --slurpfile closedPrs "$tmpdir/closed-prs.json" \
    --slurpfile closedIssues "$tmpdir/closed-issues.json" \
    '{
      updatedAt: $updatedAt,
      login: $login,
      host: $host,
      queries: {
        openPrs: $openPrsQuery,
        assignedPrs: $assignedPrsQuery,
        reviewRequestedPrs: $reviewRequestedPrsQuery,
        openIssues: $openIssuesQuery,
        assignedIssues: $assignedIssuesQuery,
        mentionedIssues: $mentionedIssuesQuery,
        subscribedIssues: $subscribedIssuesQuery,
        closedPrs: $closedPrsQuery,
        closedIssues: $closedIssuesQuery
      },
      openPrs: ($openPrs[0].data.search.nodes // []),
      assignedPrs: ($assignedPrs[0].data.search.nodes // []),
      reviewRequestedPrs: ($reviewRequestedPrs[0].data.search.nodes // []),
      openIssues: ($openIssues[0].data.search.nodes // []),
      assignedIssues: ($assignedIssues[0].data.search.nodes // []),
      mentionedIssues: ($mentionedIssues[0].data.search.nodes // []),
      subscribedIssues: ($subscribedIssues[0].data.search.nodes // []),
      closedPrs: ($closedPrs[0].data.search.nodes // []),
      closedIssues: ($closedIssues[0].data.search.nodes // [])
    }' > "$tmp_cache" \
    && mv "$tmp_cache" "$CACHE_FILE"; then
    rm -f "$CACHE_ERROR" "${CACHE_FILE}.lock" 2>/dev/null || true
    rm -rf "$tmpdir"
    return 0
  fi

  rm -f "$tmp_cache" 2>/dev/null || true
  write_cache_error "Could not write inventory cache."
  rm -rf "$tmpdir"
  rm -f "${CACHE_FILE}.lock" 2>/dev/null || true
  return 1
}

cache_is_valid() {
  [[ -f "$CACHE_FILE" ]] || return 1
  have "$JQ" || return 1
  "$JQ" -e '
    has("openPrs")
    and has("assignedPrs")
    and has("reviewRequestedPrs")
    and has("openIssues")
    and has("assignedIssues")
    and has("mentionedIssues")
    and has("subscribedIssues")
    and has("closedPrs")
    and has("closedIssues")
  ' "$CACHE_FILE" >/dev/null 2>&1
}

maybe_refresh_inventory_cache() {
  truthy "$DISABLE_GH" && return
  [[ "$CACHE_TTL_SECONDS" == <-> ]] || CACHE_TTL_SECONDS=600
  local age lock_file lock_mtime current_mtime now lock_age
  age="$(cache_age)"
  if [[ -n "$age" && "$age" -le "$CACHE_TTL_SECONDS" ]]; then
    return
  fi
  mkdir -p "${CACHE_FILE:h}" 2>/dev/null || return
  lock_file="${CACHE_FILE}.lock"
  lock_mtime="$(file_mtime "$lock_file")"
  if [[ -n "$lock_mtime" ]]; then
    now="$(now_epoch)"
    lock_age=$(( now - lock_mtime ))
    if [[ "$lock_age" -gt 300 ]]; then
      current_mtime="$(file_mtime "$lock_file")"
      [[ "$current_mtime" == "$lock_mtime" ]] && rm -f "$lock_file" 2>/dev/null || true
    fi
  fi
  ( set -C; : > "$lock_file" ) 2>/dev/null || return
  "$PLUGIN_PATH" refresh >/dev/null 2>&1 &
}

ensure_inventory_cache() {
  cache_is_valid && return 0
  truthy "$DISABLE_GH" && return 1
  write_inventory_cache >/dev/null 2>&1 || return 1
}

cache_counts() {
  local now stale
  now="$(now_epoch)"
  stale="$STALE_DAYS"
  [[ "$stale" == <-> ]] || stale=14
  "$JQ" -r --argjson now "$now" --argjson stale "$stale" '
    def days_ago($d): if ($d == null or $d == "") then 0 else ((($now - ($d | fromdateiso8601)) / 86400) | floor) end;
    def check_state: .statusCheckRollup.state // "";
    def attention:
      (.isDraft == true)
      or (.mergeable == "CONFLICTING")
      or (.mergeStateStatus == "DIRTY")
      or (check_state == "FAILURE" or check_state == "ERROR")
      or (.reviewDecision == "CHANGES_REQUESTED")
      or (.reviewDecision == "REVIEW_REQUIRED")
      or (days_ago(.updatedAt) >= $stale);
    [
      ((.openPrs | length) + (.assignedPrs | length) + (.reviewRequestedPrs | length)),
      ((.openIssues | length) + (.assignedIssues | length) + (.mentionedIssues | length) + (.subscribedIssues | length)),
      ([((.openPrs[]?, .assignedPrs[]?, .reviewRequestedPrs[]?) | select(attention))] | length)
    ] | @tsv
  ' "$CACHE_FILE" 2>/dev/null
}

render_open_prs() {
  local array_key="${1:-openPrs}" now stale private max row repo number title url health updated age comments labels color
  now="$(now_epoch)"
  stale="$STALE_DAYS"
  max="$MAX_OPEN_PRS"
  [[ "$stale" == <-> ]] || stale=14
  [[ "$max" == <-> ]] || max=30
  truthy "$SHOW_PRIVATE_BADGE" && private=1 || private=0

  "$JQ" -c --arg array_key "$array_key" --argjson now "$now" --argjson stale "$stale" --argjson max "$max" --argjson private "$private" '
    def clean: tostring | gsub("[\t\r\n|]"; " ");
    def days_ago($d): if ($d == null or $d == "") then 0 else ((($now - ($d | fromdateiso8601)) / 86400) | floor) end;
    def check_state: .statusCheckRollup.state // "";
    def repo_name: (.repository.nameWithOwner // "unknown/repo") + (if ($private == 1 and (.repository.isPrivate // false)) then " [private]" else "" end);
    def labels: [.labels.nodes[]?.name] | join(", ") | clean;
    def health:
      if .isDraft == true then "draft"
      elif (.mergeable == "CONFLICTING" or .mergeStateStatus == "DIRTY") then "merge conflict"
      elif (check_state == "FAILURE" or check_state == "ERROR") then "checks failing"
      elif .reviewDecision == "CHANGES_REQUESTED" then "changes requested"
      elif (check_state == "PENDING" or check_state == "EXPECTED") then "checks pending"
      elif .reviewDecision == "REVIEW_REQUIRED" then "review needed"
      elif days_ago(.updatedAt) >= $stale then ("stale " + (days_ago(.updatedAt) | tostring) + "d")
      else "healthy"
      end;
    def color:
      if health == "healthy" then "#2f8f46"
      elif (health == "draft" or health == "checks pending" or health == "review needed") then "#cc6633"
      else "#cc3333"
      end;
    .[$array_key][:$max][]? |
      [
        repo_name,
        ("#" + (.number | tostring)),
        (.title | clean),
        (.url // ""),
        health,
        ((.updatedAt // "")[0:10]),
        (days_ago(.updatedAt) | tostring),
        ((.comments.totalCount // 0) | tostring),
        labels,
        color
      ]
  ' "$CACHE_FILE" 2>/dev/null |
    while IFS= read -r row; do
      repo="$(emit "$row" | "$JQ" -r '.[0]')"
      number="$(emit "$row" | "$JQ" -r '.[1]')"
      title="$(emit "$row" | "$JQ" -r '.[2]')"
      url="$(emit "$row" | "$JQ" -r '.[3]')"
      health="$(emit "$row" | "$JQ" -r '.[4]')"
      updated="$(emit "$row" | "$JQ" -r '.[5]')"
      age="$(emit "$row" | "$JQ" -r '.[6]')"
      comments="$(emit "$row" | "$JQ" -r '.[7]')"
      labels="$(emit "$row" | "$JQ" -r '.[8]')"
      color="$(emit "$row" | "$JQ" -r '.[9]')"
      repo="$(menu_text "$repo")"
      title="$(menu_text "$title")"
      health="$(menu_text "$health")"
      labels="$(menu_text "$labels")"
      emit "--${repo} ${number} ${title} | href=${url} color=${color}"
      emit "----${health}; updated ${updated}; comments ${comments} | href=${url} color=${color}"
      [[ -n "$labels" ]] && emit "----Labels: ${labels} | href=${url} color=gray"
    done
}

render_open_issues() {
  local array_key="${1:-openIssues}" now stale private max row repo number title url health updated age comments labels color
  now="$(now_epoch)"
  stale="$STALE_DAYS"
  max="$MAX_OPEN_ISSUES"
  [[ "$stale" == <-> ]] || stale=14
  [[ "$max" == <-> ]] || max=30
  truthy "$SHOW_PRIVATE_BADGE" && private=1 || private=0

  "$JQ" -c --arg array_key "$array_key" --argjson now "$now" --argjson stale "$stale" --argjson max "$max" --argjson private "$private" '
    def clean: tostring | gsub("[\t\r\n|]"; " ");
    def days_ago($d): if ($d == null or $d == "") then 0 else ((($now - ($d | fromdateiso8601)) / 86400) | floor) end;
    def repo_name: (.repository.nameWithOwner // "unknown/repo") + (if ($private == 1 and (.repository.isPrivate // false)) then " [private]" else "" end);
    def labels: [.labels.nodes[]?.name] | join(", ") | clean;
    def health:
      if days_ago(.updatedAt) >= $stale then ("stale " + (days_ago(.updatedAt) | tostring) + "d")
      else "open"
      end;
    def color:
      if health == "open" then "#2f8f46" else "#cc6633" end;
    .[$array_key][:$max][]? |
      [
        repo_name,
        ("#" + (.number | tostring)),
        (.title | clean),
        (.url // ""),
        health,
        ((.updatedAt // "")[0:10]),
        (days_ago(.updatedAt) | tostring),
        ((.comments.totalCount // 0) | tostring),
        labels,
        color
      ]
  ' "$CACHE_FILE" 2>/dev/null |
    while IFS= read -r row; do
      repo="$(emit "$row" | "$JQ" -r '.[0]')"
      number="$(emit "$row" | "$JQ" -r '.[1]')"
      title="$(emit "$row" | "$JQ" -r '.[2]')"
      url="$(emit "$row" | "$JQ" -r '.[3]')"
      health="$(emit "$row" | "$JQ" -r '.[4]')"
      updated="$(emit "$row" | "$JQ" -r '.[5]')"
      age="$(emit "$row" | "$JQ" -r '.[6]')"
      comments="$(emit "$row" | "$JQ" -r '.[7]')"
      labels="$(emit "$row" | "$JQ" -r '.[8]')"
      color="$(emit "$row" | "$JQ" -r '.[9]')"
      repo="$(menu_text "$repo")"
      title="$(menu_text "$title")"
      health="$(menu_text "$health")"
      labels="$(menu_text "$labels")"
      emit "--${repo} ${number} ${title} | href=${url} color=${color}"
      emit "----${health}; updated ${updated}; comments ${comments} | href=${url} color=${color}"
      [[ -n "$labels" ]] && emit "----Labels: ${labels} | href=${url} color=gray"
    done
}

render_recently_closed() {
  local private max row kind repo number title url reason closed
  max="$MAX_CLOSED_ITEMS"
  [[ "$max" == <-> ]] || max=10
  truthy "$SHOW_PRIVATE_BADGE" && private=1 || private=0

  "$JQ" -c --argjson max "$max" --argjson private "$private" '
    def clean: tostring | gsub("[\t\r\n|]"; " ");
    def repo_name: (.repository.nameWithOwner // "unknown/repo") + (if ($private == 1 and (.repository.isPrivate // false)) then " [private]" else "" end);
    def issue_reason:
      if .stateReason == "NOT_PLANNED" then "not planned"
      elif .stateReason == "COMPLETED" then "completed"
      elif .stateReason == "REOPENED" then "reopened"
      else "closed"
      end;
    [
      (.closedPrs[]? | . + {kind: "PR", reason: (if .mergedAt then "merged" else "closed" end)}),
      (.closedIssues[]? | . + {kind: "Issue", reason: issue_reason})
    ]
    | sort_by(.closedAt // "")
    | reverse
    | .[:$max][]
    | [
        .kind,
        repo_name,
        ("#" + (.number | tostring)),
        (.title | clean),
        (.url // ""),
        .reason,
        ((.closedAt // "")[0:10])
      ]
  ' "$CACHE_FILE" 2>/dev/null |
    while IFS= read -r row; do
      kind="$(emit "$row" | "$JQ" -r '.[0]')"
      repo="$(emit "$row" | "$JQ" -r '.[1]')"
      number="$(emit "$row" | "$JQ" -r '.[2]')"
      title="$(emit "$row" | "$JQ" -r '.[3]')"
      url="$(emit "$row" | "$JQ" -r '.[4]')"
      reason="$(emit "$row" | "$JQ" -r '.[5]')"
      closed="$(emit "$row" | "$JQ" -r '.[6]')"
      repo="$(menu_text "$repo")"
      title="$(menu_text "$title")"
      reason="$(menu_text "$reason")"
      emit "--${kind} ${repo} ${number} ${title} | href=${url} color=gray"
      emit "----${reason}; closed ${closed} | href=${url} color=gray"
    done
}

render_cache_metadata() {
  local updated login host age
  updated="$("$JQ" -r '.updatedAt // "unknown"' "$CACHE_FILE" 2>/dev/null)"
  login="$("$JQ" -r '.login // "unknown"' "$CACHE_FILE" 2>/dev/null)"
  host="$("$JQ" -r '.host // "github.com"' "$CACHE_FILE" 2>/dev/null)"
  age="$(cache_age)"
  emit "--Account: ${login}@${host} | font=Menlo"
  emit "--Cache: $(shorten_path "$CACHE_FILE") | font=Menlo"
  emit "--Updated: ${updated} (${age:-unknown}s ago) | font=Menlo"
}

array_count() {
  local key="$1"
  "$JQ" -r --arg key "$key" '(.[$key] // []) | length' "$CACHE_FILE" 2>/dev/null
}

render_pr_section() {
  local title="$1" key="$2" count
  count="$(array_count "$key")"
  emit "$title"
  if [[ "${count:-0}" == "0" ]]; then
    emit "--None found | color=gray"
  else
    render_open_prs "$key"
  fi
}

render_issue_section() {
  local title="$1" key="$2" count
  count="$(array_count "$key")"
  emit "$title"
  if [[ "${count:-0}" == "0" ]]; then
    emit "--None found | color=gray"
  else
    render_open_issues "$key"
  fi
}

render_setup_rows() {
  if truthy "$DISABLE_GH"; then
    emit "--GitHub calls disabled for this run | color=gray"
  elif ! have "$GH"; then
    emit "--Missing gh: brew install gh | color=#cc3333"
  elif ! have "$JQ"; then
    emit "--Missing jq: brew install jq | color=#cc3333"
  elif ! gh_auth_status; then
    emit "--gh is not authenticated for ${GH_HOST} | color=#cc3333"
    emit "--Run: gh auth login | font=Menlo color=gray"
  elif [[ -f "$CACHE_ERROR" ]]; then
    local first_error
    first_error="$(head -1 "$CACHE_ERROR" 2>/dev/null)"
    emit "--Last refresh error: $(menu_text "$first_error") | color=#cc3333"
  else
    emit "--Waiting for first cache refresh | color=gray"
  fi
}

print_plugin_rows() {
  local root git_summary version_label release_status release_color latest_release
  root="$(plugin_repo_root)"
  version_label="$(plugin_version_label "$root")"
  if [[ -z "$root" ]]; then
    maybe_refresh_release_check
    release_status="$(release_status_label "$version_label")"
    release_color="$(release_status_color "$release_status")"
    emit "--Version: ${version_label} (${release_status}) | font=Menlo color=$release_color"
  else
    emit "--Version: ${version_label} | font=Menlo"
  fi
  emit "--Config: $(shorten_path "$CONFIG_FILE") | font=Menlo"
  emit "--Script: $(shorten_path "$PLUGIN_PATH") | font=Menlo"
  if [[ -n "$root" ]]; then
    git_summary="$(plugin_git_summary "$root")"
    emit "--Repo: $(shorten_path "$root") | font=Menlo"
    emit "--Git: ${git_summary:-unknown} | font=Menlo"
    emit "----Use git commands for development updates | color=gray"
  else
    latest_release="$(cached_latest_release_tag 2>/dev/null || true)"
    if [[ -n "$latest_release" && "$(release_tag_norm "$latest_release")" != "$(release_tag_norm "$version_label")" ]]; then
      emit "--Update to $latest_release | bash=$PLUGIN_PATH param1=update-release terminal=false refresh=true"
    else
      emit "--Update to latest release | bash=$PLUGIN_PATH param1=update-release terminal=false refresh=true"
    fi
    emit "--Check plugin update status now | bash=$PLUGIN_PATH param1=check-release terminal=false refresh=true"
  fi
  emit "--Refresh GitHub inventory now | bash=$PLUGIN_PATH param1=refresh terminal=false refresh=true"
  cache_is_valid && emit "--Open inventory cache | bash=$PLUGIN_PATH param1=open param2=cache terminal=false"
  [[ -f "$UPDATE_LOG" ]] && emit "--Open update log | bash=$PLUGIN_PATH param1=open param2=update-log terminal=false"
  emit "--Open config file | bash=$PLUGIN_PATH param1=open param2=config terminal=false refresh=true"
  emit "--Open project page | bash=$PLUGIN_PATH param1=open param2=repo terminal=false"
  emit "--Open plugin file | bash=$PLUGIN_PATH param1=open param2=plugin-file terminal=false"
}

case "${1:-}" in
  refresh)
    write_inventory_cache
    exit $?
    ;;
  check-release)
    write_release_check_cache
    exit $?
    ;;
  update-release)
    update_plugin_from_release
    exit $?
    ;;
  open)
    case "${2:-}" in
      cache)
        open_text_target "$CACHE_FILE"
        ;;
      config)
        write_default_config
        open_text_target "$CONFIG_FILE"
        ;;
      update-log)
        open_text_target "$UPDATE_LOG"
        ;;
      repo)
        open_target "$GITHUBWATCH_REPO_URL"
        ;;
      plugin-file)
        open_text_target "$PLUGIN_PATH"
        ;;
    esac
    exit 0
    ;;
esac

write_default_config >/dev/null 2>&1 || true
ensure_inventory_cache >/dev/null 2>&1 || true
cache_is_valid && maybe_refresh_inventory_cache

if cache_is_valid; then
  counts="$(cache_counts)"
  IFS=$'\t' read -r pr_count issue_count attention_count <<< "$counts"
  pr_count="${pr_count:-0}"
  issue_count="${issue_count:-0}"
  attention_count="${attention_count:-0}"
  emit "GH ${pr_count} PR$(plural "$pr_count") / ${issue_count} issue$(plural "$issue_count") / ${attention_count} attention"
else
  emit "GH setup needed"
fi

emit "---"

if cache_is_valid; then
  render_pr_section "Pull Requests Created By Me" "openPrs"
  render_pr_section "Pull Requests Assigned To Me" "assignedPrs"
  render_pr_section "Open Review Requests" "reviewRequestedPrs"

  render_issue_section "Issues Opened By Me" "openIssues"
  render_issue_section "Issues Assigned To Me" "assignedIssues"
  render_issue_section "Issues Mentioning Me" "mentionedIssues"
  render_issue_section "Subscribed / Involving Issues" "subscribedIssues"

  emit "Recently Closed"
  if [[ "$("$JQ" -r '((.closedPrs | length) + (.closedIssues | length))' "$CACHE_FILE" 2>/dev/null)" == "0" ]]; then
    emit "--None in the configured window | color=gray"
  else
    render_recently_closed
  fi

  emit "Cache"
  render_cache_metadata
else
  emit "Setup"
  render_setup_rows
fi

emit "GitHub Watch"
print_plugin_rows
