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
      url "https://github.com/jdidion/barbican/releases/download/v1.5.5/barbican-1.5.5-aarch64-apple-darwin.tar.gz"
      sha256 "ae72ec0aa32382e2e9304e2992bbe78fa13c66766a4a57a955adf95d04dbb7a8"
    end
    on_intel do
      url "https://github.com/jdidion/barbican/releases/download/v1.5.5/barbican-1.5.5-x86_64-apple-darwin.tar.gz"
      sha256 "50db4e8043172d5877e6359a18fa6a7503aec83aa0818a82a4f01ef3ae318859"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/jdidion/barbican/releases/download/v1.5.5/barbican-1.5.5-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "47f47e730e29781639570118ae8a8f8fc2930e9846957d4d3b9db1d7c90ac81f"
    end
    on_intel do
      url "https://github.com/jdidion/barbican/releases/download/v1.5.5/barbican-1.5.5-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "c55779b82f10a46b279c6fda26c21de92f602f6b161f6d0cd271505e21a71447"
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
