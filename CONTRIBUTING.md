# Contributing

Thanks for taking a look at GitHub Watch.

## Development

Run checks before opening a pull request:

```sh
./scripts/check.sh
```

Keep changes local-first and privacy-conscious. The plugin should not store GitHub tokens, send telemetry, read broad filesystem locations, or print secrets. New GitHub queries should have short timeouts where possible, use cached results, and tolerate missing tools or auth.

## Pull Requests

- Keep changes focused.
- Use a Conventional Commit PR title. `fix:` and `perf:` trigger patch releases, `feat:` triggers minor releases, and breaking changes trigger major releases after merge.
- Include a short description of the GitHub state or menu behavior being added.
- Include before/after menu output when changing display behavior, with private repo names or titles redacted when needed.
