# GitHub Watch Plan

## Problem

Open GitHub pull requests and issues can disappear from view after mail notifications are read. This is especially painful across private repositories, company repositories, public repositories, and OSS repositories because stale PRs can quietly accumulate merge conflicts, failing checks, blocked review states, or no recent activity.

## Initial Assumptions

- Use `gh` as the auth layer first. It already handles private repositories, org SSO, and host-level credentials better than a plugin-managed token file.
- Do not store a GitHub token in plugin config.
- Start with `github.com`; GitHub Enterprise support is modeled as a config variable.
- Start with PRs authored by, assigned to, or requesting review from the authenticated user.
- Start with issues authored by, assigned to, mentioning, or involving the authenticated user.
- Use cached GraphQL search results so SwiftBar refreshes do not hammer the GitHub API.
- Make query scope configurable before hard-coding broader participation modes.

## Setup Questions

1. Answered: "my PRs" should include created by me and assigned to me.
2. Answered: requested reviews should be separate as open review requests.
3. Answered: issues should include created by me and assigned to me.
4. Answered: mentioned and subscribed/involved issues should be separate sublists.
5. Answered: `github.com` is enough for now.
6. Answered: `gh auth login` is the required auth path; the plugin should show setup help.
7. Answered: caching is fine; manual refresh matters.
8. Answered: recently closed defaults to 14 days.

## MVP

- Menu headline with open PR count, open issue count, and attention count.
- Open PR lists with repo, title, age/update date, and health summary:
  - Created by me
  - Assigned to me
  - Open review requests
- Health signals: draft, merge conflict, failing checks, pending checks, changes requested, review needed, stale, healthy.
- Open issue lists with repo, title, labels, comments, and stale indicator:
  - Opened by me
  - Assigned to me
  - Mentioning me
  - Subscribed/involving me
- Recently closed list with merged/closed PRs and completed/not-planned issues.
- Click any item to open its GitHub URL.
- Tools: refresh now, open cache, open config, open project page, update release.
- Meta parity with existing local SwiftBar plugins: release asset install, dev symlink install, release self-update, CI check, PR title lint, release automation.

## Future Features

- Separate sections for authored, assigned, review-requested, and participated items.
- Per-org/repo include and exclude filters.
- "Needs me" rollup for review requests, unread comments, and requested changes.
- Stale thresholds by repository or organization.
- Local notification when a PR first becomes conflicted or checks fail after passing.
- Optional GitHub Enterprise host list.
- Optional local archive of recently closed items to show close reason history beyond the search window.
