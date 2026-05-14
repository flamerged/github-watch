# GitHub Watch

GitHub Watch is a SwiftBar/xbar-compatible menu bar plugin for tracking your open GitHub pull requests and issues across repositories.

It is built for the mailbox problem: after notifications are read, open work can disappear from view. GitHub Watch keeps a compact menu of open PRs, open issues, and recently closed items, with health signals for merge conflicts, failing checks, review state, draft state, and stale activity.

## Features

- Finds open pull requests authored by, assigned to, or requesting review from the authenticated `gh` user.
- Finds open issues authored by, assigned to, mentioning, or involving the authenticated `gh` user.
- Shows PR health signals: draft, merge conflict, failing checks, pending checks, changes requested, review needed, stale, or healthy.
- Shows recently closed PRs and issues with merged/closed/completed/not-planned status where GitHub exposes it.
- Clicks open the PR or issue URL in your browser.
- Uses `gh` for authentication. No GitHub token is stored in plugin config.
- Caches GitHub API results so normal SwiftBar refreshes stay fast and low-noise.
- Supports plugin version checks and release self-update for copied plugin installs.
- Supports source checkout installs with git metadata and no self-overwrite.

## Install

### SwiftBar

1. Install [SwiftBar](https://github.com/swiftbar/SwiftBar).
2. Install runtime dependencies:

```sh
brew install gh jq
gh auth login
```

3. Download the latest release plugin into your SwiftBar plugin folder:

```sh
mkdir -p "$HOME/SwiftBarPlugins"
curl -fsSL \
  https://github.com/flamerged/github-watch/releases/latest/download/github-watch.5m.sh \
  -o "$HOME/SwiftBarPlugins/github-watch.5m.sh"
chmod +x "$HOME/SwiftBarPlugins/github-watch.5m.sh"
```

SwiftBar will pick up `github-watch.5m.sh` and refresh every 5 minutes.

### xbar

GitHub Watch uses the BitBar/xbar stdout menu format and includes xbar metadata. Install the latest release asset into your xbar plugin folder:

```sh
mkdir -p "$HOME/Library/Application Support/xbar/plugins"
curl -fsSL \
  https://github.com/flamerged/github-watch/releases/latest/download/github-watch.5m.sh \
  -o "$HOME/Library/Application Support/xbar/plugins/github-watch.5m.sh"
chmod +x "$HOME/Library/Application Support/xbar/plugins/github-watch.5m.sh"
```

### Development Install

Clone the repo only when you want a source checkout for development:

```sh
git clone https://github.com/flamerged/github-watch.git
cd github-watch
./scripts/install-dev-swiftbar.sh "$HOME/SwiftBarPlugins"
```

Release installs show whether the installed plugin is current or whether a newer release is available. `Update to latest release` runs in the background, writes to `GITHUBWATCH_UPDATE_LOG`, and replaces the plugin with the latest release asset. Source checkout installs show the current branch and commit for diagnostics, but hide the menu updater to avoid overwriting checkout-managed files. Development updates should use normal git commands in the checkout.

## Requirements

- `zsh`
- `gh`
- `jq`
- `curl` for plugin release checks and self-update

macOS ships `zsh`. Install the rest with Homebrew:

```sh
brew install gh jq curl
```

Authenticate `gh` with scopes that can see the repositories you care about:

```sh
gh auth login
gh auth status
```

For private organization repositories, make sure the active GitHub token has organization SSO access where required.

## Configuration

GitHub Watch works without configuration after `gh auth login`, but these environment variables can tailor it to your setup:

The plugin also supports a local config file at `~/.config/github-watch/config.env`. Open or create it from the `GitHub Watch` menu section with `Open config file`. The file accepts simple `GITHUBWATCH_KEY=value` lines; it is parsed as data and is not sourced as shell code. Environment variables supplied by the launcher override values from this file.

| Variable | Default | Purpose |
| --- | --- | --- |
| `GITHUBWATCH_CONFIG_FILE` | `~/.config/github-watch/config.env` | GitHub Watch config file path |
| `GITHUBWATCH_GH_HOST` | `github.com` | GitHub host for `gh api --hostname` |
| `GITHUBWATCH_CACHE_FILE` | `~/.cache/github-watch/inventory.json` | Cached inventory JSON path |
| `GITHUBWATCH_CACHE_TTL_SECONDS` | `600` | Seconds between automatic inventory refreshes |
| `GITHUBWATCH_CLOSED_DAYS` | `14` | Recently closed search window |
| `GITHUBWATCH_STALE_DAYS` | `14` | Days without updates before an item is marked stale |
| `GITHUBWATCH_MAX_OPEN_PRS` | `30` | Max open PRs fetched and rendered |
| `GITHUBWATCH_MAX_OPEN_ISSUES` | `30` | Max open issues fetched and rendered |
| `GITHUBWATCH_MAX_CLOSED_ITEMS` | `10` | Max recently closed PRs and issues fetched |
| `GITHUBWATCH_PR_SEARCH` | `is:pr is:open author:{login} archived:false sort:updated-desc` | Open PR search template |
| `GITHUBWATCH_ASSIGNED_PR_SEARCH` | `is:pr is:open assignee:{login} archived:false sort:updated-desc` | Assigned PR search template |
| `GITHUBWATCH_REVIEW_REQUESTED_PR_SEARCH` | `is:pr is:open review-requested:{login} archived:false sort:updated-desc` | Open review-requested PR search template |
| `GITHUBWATCH_ISSUE_SEARCH` | `is:issue is:open author:{login} archived:false sort:updated-desc` | Open issue search template |
| `GITHUBWATCH_ASSIGNED_ISSUE_SEARCH` | `is:issue is:open assignee:{login} archived:false sort:updated-desc` | Assigned issue search template |
| `GITHUBWATCH_MENTIONED_ISSUE_SEARCH` | `is:issue is:open mentions:{login} archived:false sort:updated-desc` | Mentioned issue search template |
| `GITHUBWATCH_SUBSCRIBED_ISSUE_SEARCH` | `is:issue is:open involves:{login} -author:{login} -assignee:{login} -mentions:{login} archived:false sort:updated-desc` | Involved/subscribed issue approximation |
| `GITHUBWATCH_CLOSED_PR_SEARCH` | `is:pr author:{login} archived:false closed:>={since} sort:updated-desc` | Recently closed PR search template |
| `GITHUBWATCH_CLOSED_ISSUE_SEARCH` | `is:issue author:{login} archived:false closed:>={since} sort:updated-desc` | Recently closed issue search template |
| `GITHUBWATCH_SHOW_PRIVATE_BADGE` | `1` | Mark private repositories in menu rows |
| `GITHUBWATCH_REPO_DIR` | empty | Optional GitHub Watch git checkout for source metadata |
| `GITHUBWATCH_REPO_URL` | `https://github.com/flamerged/github-watch` | Project page opened from the menu |
| `GITHUBWATCH_RELEASE_ASSET_URL` | `https://github.com/flamerged/github-watch/releases/latest/download/github-watch.5m.sh` | HTTPS latest release asset URL used by copied-plugin updates |
| `GITHUBWATCH_UPDATE_LOG` | `~/.cache/github-watch/update.log` | Update log path |
| `GITHUBWATCH_CHECK_RELEASE_UPDATES` | `1` | Set to `0` to disable cached plugin release checks |
| `GITHUBWATCH_RELEASE_CHECK_TTL_SECONDS` | `86400` | Seconds between latest-release checks |
| `GITHUBWATCH_RELEASE_CHECK_CACHE` | `~/.cache/github-watch/release-check.tsv` | Latest-release check cache path |

The `{login}` and `{since}` placeholders are replaced at refresh time. GitHub search does not expose a clean "all subscribed issues" qualifier through `gh` search, so the default subscribed section uses `involves:{login}` while excluding authored, assigned, and mentioned issues. Tune `GITHUBWATCH_SUBSCRIBED_ISSUE_SEARCH` if that section is too broad or too narrow.

## Privacy And Security

GitHub Watch uses the local `gh` CLI as its authentication boundary. It does not ask for, read, or store a GitHub token.

Inventory data is cached locally at `GITHUBWATCH_CACHE_FILE`. That cache includes repository names, PR/issue titles, URLs, labels, and state fields returned by GitHub. Do not screen-share the menu or cache file if those names are sensitive.

The plugin talks to GitHub only when refreshing its inventory or checking the latest plugin release. Normal menu redraws read the local cache.

## Development

Run the local checks:

```sh
./scripts/check.sh
```

The checks run `zsh -n` and a smoke execution with GitHub calls disabled.

## Releases

PR titles should use Conventional Commits. `fix:` and `perf:` changes produce patch releases, `feat:` changes produce minor releases, and breaking changes produce major releases.

After a releasable PR is squash-merged to `main`, the release workflow tags the merge commit and creates the GitHub Release. It also uploads a release copy of `github-watch.5m.sh` with the release version embedded. It does not open a separate release PR.

## License

MIT
