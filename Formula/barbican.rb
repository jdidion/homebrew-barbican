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
      url "https://github.com/jdidion/barbican/releases/download/v1.5.2/barbican-1.5.2-aarch64-apple-darwin.tar.gz"
      sha256 "f4c74e12b8cf6151863cd26454fa66e6968a4eb5489b07ca3f1cd0b438ec0679"
    end
    on_intel do
      url "https://github.com/jdidion/barbican/releases/download/v1.5.2/barbican-1.5.2-x86_64-apple-darwin.tar.gz"
      sha256 "c1102bf82526b4863f8f5676a10c90d1a91beb4876a561067112d596acf39406"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/jdidion/barbican/releases/download/v1.5.2/barbican-1.5.2-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "55a9a0b530020f82033da983ec1eebea7345e11b8fff2bebf063a58d893d1a70"
    end
    on_intel do
      url "https://github.com/jdidion/barbican/releases/download/v1.5.2/barbican-1.5.2-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "072987ba9c2006749cac8760ca7155a7ea7dd4bf993f222da7b7ae3ce77ce71e"
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
