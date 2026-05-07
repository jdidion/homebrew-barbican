# Homebrew formula for Barbican — Claude Code safety layer.
#
# Installs the main `barbican` binary and the five classifier-gated
# wrapper binaries (`barbican-shell`, `-python`, `-node`, `-ruby`,
# `-perl`). Does NOT run `barbican install` automatically — that step
# edits `~/.claude/settings.json` and registers an MCP server, which is
# user configuration, not Homebrew-managed state. See the caveats
# block below.
class Barbican < Formula
  desc "Pre-execution safety checks for AI-generated shell commands (Claude Code hook + MCP)"
  homepage "https://github.com/jdidion/barbican"
  version "1.5.0"
  license "MIT"

  # Prebuilt release binaries from the GitHub Releases page. Every
  # asset is covered by a Sigstore build-provenance attestation
  # (verifiable with `gh attestation verify TARBALL --repo
  # jdidion/barbican`); the SHA256s below pin the specific bytes this
  # formula was audited against.
  on_macos do
    on_arm do
      url "https://github.com/jdidion/barbican/releases/download/v#{version}/barbican-#{version}-aarch64-apple-darwin.tar.gz"
      sha256 "3a00c414118fd5896d87cf4c3ea4aa1933c34051fb5964bbcef14def6b7b0149"
    end
    on_intel do
      url "https://github.com/jdidion/barbican/releases/download/v#{version}/barbican-#{version}-x86_64-apple-darwin.tar.gz"
      sha256 "bc9802f22944512e11987ace051b8ad43b2d778d6fbec63a1c22818c2c1c26db"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/jdidion/barbican/releases/download/v#{version}/barbican-#{version}-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "14b05f9314a914b45892c0e3df4abae1cdba4ce7db421f45f3d14169852f0d31"
    end
    on_intel do
      url "https://github.com/jdidion/barbican/releases/download/v#{version}/barbican-#{version}-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "326d189ef6dbb318d016842cfeb1793d227b3e787a15750d45ace38ada7d9915"
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
