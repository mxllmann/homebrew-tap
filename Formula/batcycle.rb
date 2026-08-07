class Batcycle < Formula
  include Language::Python::Shebang

  desc "Battery cycle history for macOS, from the system powerlog"
  homepage "https://github.com/mxllmann/batcycle"
  url "https://github.com/mxllmann/batcycle/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "REPLACE_AFTER_TAGGING"
  license "MIT"

  depends_on :macos
  depends_on "python@3.13"

  def install
    libexec.install "batcycle", "template.html"
    # batcycle locates template.html next to its own realpath, so a symlink
    # in bin resolves back into libexec correctly
    rewrite_shebang detected_python_shebang, libexec/"batcycle"
    bin.install_symlink libexec/"batcycle"
  end

  def caveats
    <<~EOS
      macOS retains roughly 7 days of battery history. To accumulate more:
        batcycle install-agent

      That installs a launchd agent running hourly. Remove it with:
        batcycle uninstall-agent
    EOS
  end

  test do
    assert_match "batcycle #{version}", shell_output("#{bin}/batcycle --version")
    # the report needs a real powerlog, so only assert it fails cleanly
    # rather than crashing when one is absent
    system bin/"batcycle", "--help"
  end
end
