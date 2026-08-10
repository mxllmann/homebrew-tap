class Batcycle < Formula
  include Language::Python::Shebang

  desc "Battery cycle history for macOS, from the system powerlog"
  homepage "https://github.com/mxllmann/batcycle"
  url "https://github.com/mxllmann/batcycle/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "2aacd0a67327083d7194852295fe69c770e58ae24aebb939ca271d7f5b4b9b4b"
  license "MIT"

  depends_on :macos
  depends_on "python@3.13"

  # The menu bar app is built from source deliberately. A prebuilt .app arrives
  # with com.apple.quarantine attached and Gatekeeper blocks it unless it carries
  # a Developer ID signature and has been notarised — $99/year. A binary the
  # compiler produced on this machine never gets that attribute, so it launches
  # cleanly with only an ad-hoc signature.
  #
  # The cost is a Swift 6 toolchain, which Command Line Tools provides on recent
  # macOS. Homebrew guarantees CLT is present, so there is no `depends_on xcode`
  # here; an older toolchain fails at `swift build` with the compiler's own
  # message, which is clearer than anything this formula could substitute.

  def install
    # The CLI keeps its own name with no extension, because the filename is the
    # command name.
    libexec.install "batcycle", "template.html"
    rewrite_shebang detected_python_shebang, libexec/"batcycle"
    bin.install_symlink libexec/"batcycle"

    cd "menubar" do
      system "./build-app.sh", "BatcycleMenuBar"
      # Into prefix, not bin: a .app is a directory and nothing should try to
      # link it. `batcycle start` finds it at <prefix>/BatcycleMenuBar.app, one
      # level up from the libexec the CLI runs from.
      prefix.install "build/BatcycleMenuBar.app"
    end
  end

  def caveats
    <<~EOS
      Start the menu bar app:
        batcycle start

      It appears in the menu bar as a ring showing how far you are into the
      current charge cycle, collects hourly, and starts at login from then on.
      Turn that off in its own menu.

      The CLI works on its own if you would rather not run the app:
        batcycle           # build the dashboard and open it
        batcycle report    # the same numbers as text
        batcycle --json    # machine-readable

      Before uninstalling, run:
        batcycle stop

      `brew uninstall` cannot reach outside this prefix, so without that the
      launch agent in ~/Library/LaunchAgents survives, pointing at a deleted
      executable that launchd retries at every login. `stop` leaves your
      collected history in place and prints where it is.
    EOS
  end

  # No `service` block on purpose. `brew services` would write a second launch
  # agent beside the one the app writes for itself, and both would start a
  # collector appending to the same samples.csv — two processes reading the same
  # last-seen timestamp before appending, which duplicates rows and can interleave
  # writes mid-buffer. Two mechanisms for one job is a footgun, not a
  # convenience, so start-at-login has exactly one owner: the app.

  test do
    assert_match "batcycle #{version}", shell_output("#{bin}/batcycle --version")

    # A report needs a real powerlog, which the test sandbox has no business
    # reading, so only assert the entry points resolve.
    system bin/"batcycle", "--help"

    # The app has to exist where `batcycle start` looks for it. This is the
    # assertion that catches a layout change silently breaking installation.
    assert_predicate prefix/"BatcycleMenuBar.app/Contents/MacOS/BatcycleMenuBar",
                     :executable?

    # And it has to be signed, or arm64 refuses to execute it at all.
    system "codesign", "--verify", prefix/"BatcycleMenuBar.app"
  end
end
