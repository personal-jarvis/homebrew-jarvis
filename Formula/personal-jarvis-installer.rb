class PersonalJarvisInstaller < Formula
  desc "Supply-chain hardened installer for Personal Jarvis (4 trust axes)"
  homepage "https://github.com/personal-jarvis/personal-jarvis"
  url "https://github.com/personal-jarvis/personal-jarvis/releases/download/v0.5.1-supplychain-wave5-audit-fixes/install-verify.sh"
  version "0.5.1-supplychain-wave5-audit-fixes"
  sha256 "4c9b076bffba48fa26d4ef07f3666d3400382d1e383537cc551733d43257ea73"
  license "MIT"

  # PINNED to the v0.5.1-supplychain-wave5-audit-fixes release.
  #
  # The url points at a single release asset rather than the source
  # tarball, because the installer is a single executable shell script
  # that we re-publish per release with cosign + offline + SLSA L3 +
  # ML-DSA-65 signatures alongside it. The Homebrew tap MUST never pull
  # from `master`/`HEAD` — that defeats the whole point of Wave 4 (the
  # package manager's signing chain is only meaningful if the pinned
  # artifact is immutable).
  #
  # Wave-5 bump (audit fixes, 2026-05-27):
  # - Tag-binding cross-check: stage [7/13] now extracts the
  #   @refs/tags/<X> suffix from the cosign SAN cert and refuses if
  #   it does not match \$TAG (closes downgrade-replay).
  # - New axis E (payload-commit pin): install-verify fetches +
  #   verifies payload-commit.txt (the tagged commit SHA), then
  #   install.sh checks out --detach to that SHA before running.
  #   Closes the cloned-main-is-unsigned gap.
  # - in-toto layout renamed layout-content-anchor.json with honest
  #   _type=content-anchor; docs no longer overclaim in-toto signing.
  # - Verifier now spans 14 stages plus axis E; SHA256 above is taken
  #   verbatim from the v0.5.1 release's checksums.txt.

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
    installer = bin/"personal-jarvis-installer"
    assert_path_exists installer
    assert_predicate installer, :executable?
    contents = File.read(installer)
    assert_match "Personal Jarvis", contents
    assert_match "supply-chain", contents
    assert_match "EXPECTED_REPO=\"personal-jarvis/personal-jarvis\"", contents
  end
end
