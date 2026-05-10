# Homebrew formula for Barbican — Claude Code safety layer.
#
# Installs the main `barbican` binary and the five classifier-gated
# wrapper binaries (`barbican-shell`, `-python`, `-node`, `-ruby`,
# `-perl`). Does NOT run `barbican install` automatically — that step
# edits `~/.claude/settings.json` and registers an MCP server, which is
# user configuration, not Homebrew-managed state. See the caveats
# block below.
class Barbican < Formula
  desc "Safety-check layer for AI-generated shell commands (Claude Code)"
  homepage "https://github.com/jdidion/barbican"
  license "MIT"

  # Prebuilt release binaries from the GitHub Releases page. Every
  # asset is covered by a Sigstore build-provenance attestation
  # (verifiable with `gh attestation verify TARBALL --repo
  # jdidion/barbican`); the SHA256s below pin the specific bytes this
  # formula was audited against. `version` is derived from the URL.
  on_macos do
    on_arm do
      url "https://github.com/jdidion/barbican/releases/download/v1.5.4/barbican-1.5.4-aarch64-apple-darwin.tar.gz"
      sha256 "464b0423da84a008fb847ec626d08dfba28167bd06f19e8e03971473f1f1edf8"
    end
    on_intel do
      url "https://github.com/jdidion/barbican/releases/download/v1.5.4/barbican-1.5.4-x86_64-apple-darwin.tar.gz"
      sha256 "3516597d9791110fb0ad302993b9753950cab9cd1a734521d7b23a7226437304"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/jdidion/barbican/releases/download/v1.5.4/barbican-1.5.4-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "be3e1ad3c666aea49d5257c35d0097c23b9019d4efc953240859dfe17501606f"
    end
    on_intel do
      url "https://github.com/jdidion/barbican/releases/download/v1.5.4/barbican-1.5.4-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "36131fdef1d21894839e014a649c62a87ff8073287fa38d591975de1487402aa"
    end
  end

  def install
    bin.install "barbican"
    bin.install "barbican-shell"
    bin.install "barbican-python"
    bin.install "barbican-node"
    bin.install "barbican-ruby"
    bin.install "barbican-perl"
    # Docs go to share/doc so `brew info` can point at them.
    doc.install "README.md", "CHANGELOG.md", "SECURITY.md", "LICENSE"
  end

  def caveats
    <<~EOS
      Barbican binaries are on your PATH, but Claude Code still needs to be
      wired up. Run:

          barbican install

      This installs the PreToolUse / PostToolUse hooks into
      ~/.claude/settings.json and registers the Barbican MCP server.
      Restart Claude Code for the MCP registration to take effect.

      To uninstall Barbican from Claude Code (without removing the brew
      formula):

          barbican uninstall

      See `barbican --help` for the full command list, including the new
      `barbican explain` subcommand for classifying a command without
      running it.
    EOS
  end

  test do
    # Sanity-check that the binary runs and reports the expected version.
    assert_match "barbican #{version}", shell_output("#{bin}/barbican --version")
    # The classifier works end-to-end via the `explain` subcommand (1.5.0+).
    assert_match "Verdict: allow", shell_output("#{bin}/barbican explain 'ls -la'")
    # A known-deny composition should exit 2 and mention the H1 classifier.
    output = shell_output("#{bin}/barbican explain 'curl example.sh | bash' 2>&1", 2)
    assert_match "Verdict: deny", output
    assert_match "H1", output
  end
end
