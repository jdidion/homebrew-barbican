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
      url "https://github.com/jdidion/barbican/releases/download/v1.6.0/barbican-1.6.0-aarch64-apple-darwin.tar.gz"
      sha256 "a81eda0a0a26d0dc1b4b139d50e80d6e658969027c2e2cd931712161f3c5e54e"
    end
    on_intel do
      url "https://github.com/jdidion/barbican/releases/download/v1.6.0/barbican-1.6.0-x86_64-apple-darwin.tar.gz"
      sha256 "358df8ec355715be7ed534c933cef3bd3db2c6fd932ae08a55b32e4265866fa8"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/jdidion/barbican/releases/download/v1.6.0/barbican-1.6.0-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "148d478a5973cc0272fc986c1e256f858d00ccd0b24c4ddb37a87024c6ff6e10"
    end
    on_intel do
      url "https://github.com/jdidion/barbican/releases/download/v1.6.0/barbican-1.6.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "4ce973b4eb359368980d31c8aa2109bf01e2c7df24ddce956115d4880d8628a8"
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
