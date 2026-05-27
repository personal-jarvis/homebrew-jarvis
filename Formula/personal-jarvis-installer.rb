class PersonalJarvisInstaller < Formula
  desc "Supply-chain hardened installer for Personal Jarvis (cosign + offline Ed25519 + SLSA L3 + in-toto)"
  homepage "https://github.com/personal-jarvis/personal-jarvis"
  license "MIT"

  # PINNED to the v0.4.0-supplychain-wave3 release.
  #
  # IMPORTANT for SA-5 (Wave 4 integrator): when v0.5.0-wave4 lands, bump
  # `url`, `version`, and `sha256` to the new release. The url SHOULD point
  # at a single release asset rather than the source tarball, because the
  # installer is a single executable shell script that we re-publish per
  # release with cosign + offline + SLSA signatures alongside it. The
  # Homebrew tap MUST never pull from `master`/`HEAD` — that defeats the
  # whole point of Wave 4 (the package manager's signing chain is only
  # meaningful if the pinned artifact is immutable).
  url "https://github.com/personal-jarvis/personal-jarvis/releases/download/v0.4.0-supplychain-wave3/install-verify.sh"
  version "0.4.0-supplychain-wave3"
  sha256 "d81582569a828b99589b549a8d7544029dbd15a823fa5bba1d5abbc369bfed02"

  def install
    # The downloaded file is a single executable shell script (not an
    # archive). Homebrew will have placed it in the cached path under its
    # `url`-derived basename; rename it to the canonical bin name during
    # install so the user invokes `personal-jarvis-installer`, not
    # `install-verify.sh`.
    bin.install "install-verify.sh" => "personal-jarvis-installer"
  end

  test do
    # The installer is a 12-stage verifier that fails closed; running it
    # bare would try to download cosign + the release bundle. For a `brew
    # test` smoke check we only assert that the script is present, is the
    # right verifier (not some random shell file), and has a recognisable
    # banner. This is the strongest meaningful test we can run without
    # network + signing material in the test sandbox.
    installer = "#{bin}/personal-jarvis-installer"
    assert_predicate Pathname.new(installer), :exist?
    assert_predicate Pathname.new(installer), :executable?
    contents = File.read(installer)
    assert_match "Personal Jarvis", contents
    assert_match "supply-chain", contents
    assert_match "EXPECTED_REPO=\"personal-jarvis/personal-jarvis\"", contents
  end
end
