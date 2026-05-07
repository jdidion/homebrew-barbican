# homebrew-barbican

Homebrew tap for [Barbican](https://github.com/jdidion/barbican) — a safety layer for [Claude Code](https://claude.com/claude-code) delivered as a single static Rust binary.

## Install

```sh
brew install jdidion/barbican/barbican
barbican install        # wires hooks + MCP server into ~/.claude
```

Then restart Claude Code for the MCP registration to take effect.

Barbican's documentation, including the security model and known limits, lives in the main repo: [jdidion/barbican](https://github.com/jdidion/barbican). See [`SECURITY.md`](https://github.com/jdidion/barbican/blob/main/SECURITY.md) and the project [`README.md`](https://github.com/jdidion/barbican/blob/main/README.md) before adopting.

## Why a tap instead of direct download?

Homebrew strips the `com.apple.quarantine` xattr on binaries it installs, so you don't hit Gatekeeper warnings. Barbican's binaries aren't Apple-codesigned yet (that's on the roadmap); until they are, `brew` is the friction-free install path on macOS.

The tarballs themselves are identical to the ones on the [GitHub Releases page](https://github.com/jdidion/barbican/releases) and carry [Sigstore build-provenance attestations](https://docs.github.com/en/actions/security-guides/using-artifact-attestations-to-establish-provenance-for-builds). If you prefer the direct-download path, the tarball SHA256 in this formula pins the same bytes `gh attestation verify` would validate.

## Releases

The formula auto-bumps via a workflow in the main repo that opens a PR on this tap when a new version is tagged and released. Manual bump:

```sh
brew bump-formula-pr --version=<new-version> barbican
```

## License

MIT, matching the upstream project.
