class PersonalJarvisInstaller < Formula
  desc "Supply-chain hardened installer for Personal Jarvis (5 trust axes + Wave 6 pip hash-pin)"
  homepage "https://github.com/personal-jarvis/personal-jarvis"
  url "https://github.com/personal-jarvis/personal-jarvis/releases/download/v0.6.0-supplychain-wave6/install-verify.sh"
  version "0.6.0-supplychain-wave6"
  sha256 "c9b867bdc95a2675501964ad3e562e2bd2ce22894aaedf1e8b8000517415c3ce"
  license "MIT"

  # PINNED to the v0.6.0-supplychain-wave6 release.
  #
  # The url points at a single release asset rather than the source
  # tarball, because the installer is a single executable shell script
  # that we re-publish per release with cosign + offline + SLSA L3 +
  # ML-DSA-65 signatures alongside it. The Homebrew tap MUST never pull
  # from `master`/`HEAD` — that defeats the whole point of Wave 4 (the
  # package manager's signing chain is only meaningful if the pinned
  # artifact is immutable).
  #
  # Wave-6 bump (pip hash-pin + audit, 2026-05-27):
  # - New CI gate `pip-audit -r requirements.txt --strict` runs before
  #   any signing work — a CVE in any transitive Python dep blocks
  #   the release at the earliest possible point.
  # - `requirements.txt` is now a `pip-compile --generate-hashes`
  #   lockfile (~3200 `--hash=sha256:` lines across ~170 packages)
  #   signed under all five trust axes alongside `install.sh`.
  # - `install-verify.sh` runs a new Wave-6 stage that fetches +
  #   authenticates `requirements.txt` against the same axes
  #   (Fulcio keyless, offline Ed25519, ML-DSA-65) before
  #   `installer.py` runs `pip install --require-hashes` from it.
  # - `verify-wave6.sh` at the repo root is the goal-terminal proof:
  #   clean venv ⇒ hash-pinned install ⇒ import jarvis ⇒ pip-audit
  #   --strict ⇒ prints exactly `WAVE6_OK` on success.
  # - Threat model docs/supply-chain/threat-model.md §11 documents
  #   the new pillar plus the residual gaps (Linux-only lockfile,
  #   unhashed pyproject.toml, unhashed pip-audit).
  # - SHA256 above is taken verbatim from the v0.6.0 release's
  #   checksums.txt.

  def install
    # The downloaded file is a single executable shell script (not an
    # archive). Homebrew will have placed it in the cached path under its
    # `url`-derived basename; rename it to the canonical bin name during
    # install so the user invokes `personal-jarvis-installer`, not
    # `install-verify.sh`.
    bin.install "install-verify.sh" => "personal-jarvis-installer"
  end

  test do
    # The installer is a 14-stage verifier (plus axis E + Wave 6) that
    # fails closed; running it bare would try to download cosign + the
    # release bundle + the PQ ML-DSA-65 verification material + the
    # hash-pinned dependency lockfile. For a `brew test` smoke check we
    # only assert that the script is present, is the right verifier (not
    # some random shell file), and has a recognisable banner. This is
    # the strongest meaningful test we can run without network + signing
    # material in the test sandbox.
    installer = bin/"personal-jarvis-installer"
    assert_path_exists installer
    assert_predicate installer, :executable?
    contents = File.read(installer)
    assert_match "Personal Jarvis", contents
    assert_match "supply-chain", contents
    assert_match "EXPECTED_REPO=\"personal-jarvis/personal-jarvis\"", contents
    # Wave 6: confirm the verifier carries the new lockfile-authentication stage.
    assert_match "Wave 6", contents
    assert_match "requirements.txt", contents
  end
end
