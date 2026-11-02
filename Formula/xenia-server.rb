# Xenia, from its signed release archives (https://xenia-platform.github.io).
# Written by tools/formula.sh from xenia's contrib/homebrew/xenia-server.rb.in
# for each release: edits here go with the next one.
class XeniaServer < Formula
  desc "Web server and reverse proxy, configured in JavaScript"
  homepage "https://xenia-platform.github.io"
  version "0.16.0" # the archives' names end in the architecture, which Homebrew takes for one
  license :cannot_represent # the Xenia License: free to use, binaries only

  on_macos do
    depends_on arch: :arm64
    on_arm do
      url "https://github.com/xenia-platform/releases/releases/download/v0.16.0/xenia-0.16.0-macos-arm64.tar.gz"
      sha256 "47263dc1a8099098007735bf4f4a60ff9cf55d415b82953bd406c5ce3f9afbee"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/xenia-platform/releases/releases/download/v0.16.0/xenia-0.16.0-linux-x86_64.tar.gz"
      sha256 "637fc87e0805df11a9f3aa76156000f35808f702f2a66da86731110e23f06668"
    end
    on_arm do
      url "https://github.com/xenia-platform/releases/releases/download/v0.16.0/xenia-0.16.0-linux-arm64.tar.gz"
      sha256 "3760f2d9c754dcec448675c5f9652d1a617494682e18ad3d4c1f03aac8b5a72e"
    end
  end

  def install
    bin.install "xenia"
    pkgshare.install "examples", "types"
    doc.install "README.md", "SECURITY.md", "CHANGELOG.md", "docs"
    prefix.install "LICENSE", "THIRD_PARTY_LICENSES"
  end

  # The example project, the first time: a config edited since stays.
  post_install_steps do
    mkdir_p "log/xenia", base: :var
    unless_path_exists "xenia/xenia.conf.js", base: :etc do
      mkdir_p "xenia", base: :etc
      copy "examples/xenia.conf.js", "xenia/xenia.conf.js", source_base: :pkgshare, target_base: :etc
      copy "examples/pages.js", "xenia/pages.js", source_base: :pkgshare, target_base: :etc
      copy "examples/www", "xenia/www", source_base: :pkgshare, target_base: :etc, recursive: true
    end
  end

  def caveats
    <<~EOS
      The config is #{etc}/xenia/xenia.conf.js, the example project to start
      from. As a service, xenia serves it on http://127.0.0.1:8080/:
        brew services start xenia-server
      and reloads it with: brew services restart xenia-server
    EOS
  end

  service do
    run [opt_bin/"xenia", "--config", etc/"xenia/xenia.conf.js", "--listen", "127.0.0.1:8080",
         "--access-log", var/"log/xenia/access.log"]
    working_dir etc/"xenia"
    keep_alive true
    log_path var/"log/xenia/xenia.log"
    error_log_path var/"log/xenia/xenia.log"
  end

  test do
    assert_match "xenia #{version} ", shell_output("#{bin}/xenia --version")
    cp_r pkgshare/"examples/.", testpath
    system bin/"xenia", "check", "xenia.conf.js"
  end
end
