class PersonalJarvisInstaller < Formula
  desc "Supply-chain hardened installer for Personal Jarvis (cosign + offline Ed25519 + SLSA L3 + in-toto)"
  homepage "https://github.com/personal-jarvis/personal-jarvis"
  license "MIT"

  # PINNED to the v0.5.0-supplychain-wave4 release.
  #
  # The url points at a single release asset rather than the source
  # tarball, because the installer is a single executable shell script
  # that we re-publish per release with cosign + offline + SLSA L3 +
  # ML-DSA-65 signatures alongside it. The Homebrew tap MUST never pull
  # from `master`/`HEAD` — that defeats the whole point of Wave 4 (the
  # package manager's signing chain is only meaningful if the pinned
  # artifact is immutable).
  #
  # Wave-4 bump (SA-5, 2026-05-27):
  # - Verifier is now 14 stages (0/13..13/13); stages 12-13 carry the
  #   ML-DSA-65 PQ axis. Stage 13/13 cleanly skips when the host's
  #   OpenSSL is older than 3.5 (transition mode) with an explicit
  #   warning rather than a hard fail.
  # - SHA256 is computed over the v0.5 install-verify.sh source at the
  #   squash-merge commit on `main`; the signing workflow publishes
  #   byte-identical content to the release asset.
  url "https://github.com/personal-jarvis/personal-jarvis/releases/download/v0.5.0-supplychain-wave4/install-verify.sh"
  version "0.5.0-supplychain-wave4"
  sha256 "742746d9073382195728d730c31cd72aaf7316fdc81dbac9ed6f77eeb9376c52"

  def install
    # The downloaded file is a single executable shell script (not an
    # archive). Homebrew will have placed it in the cached path under its
    # `url`-derived basename; rename it to the canonical bin name during
    # install so the user invokes `personal-jarvis-installer`, not
    # `install-verify.sh`.
    bin.install "install-verify.sh" => "personal-jarvis-installer"
  end

  test do
    # The installer is a 14-stage verifier that fails closed; running it
    # bare would try to download cosign + the release bundle + the PQ
    # ML-DSA-65 verification material. For a `brew test` smoke check we
    # only assert that the script is present, is the right verifier (not
    # some random shell file), and has a recognisable banner. This is the
    # strongest meaningful test we can run without network + signing
    # material in the test sandbox.
    installer = "#{bin}/personal-jarvis-installer"
    assert_predicate Pathname.new(installer), :exist?
    assert_predicate Pathname.new(installer), :executable?
    contents = File.read(installer)
    assert_match "Personal Jarvis", contents
    assert_match "supply-chain", contents
    assert_match "EXPECTED_REPO=\"personal-jarvis/personal-jarvis\"", contents
  end
end
