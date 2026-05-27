# Personal Jarvis Homebrew Tap

Official Homebrew tap for [Personal Jarvis](https://github.com/personal-jarvis/personal-jarvis) — the public, supply-chain-hardened install path for macOS and Linuxbrew.

## What this tap provides

A single formula, `personal-jarvis-installer`, which downloads and installs the Personal Jarvis bootstrap verifier (`install-verify.sh`). The verifier is the 12-stage entry point that, when run, performs cosign + offline Ed25519 + SLSA L3 + in-toto checks before unpacking and installing the Personal Jarvis runtime.

This tap is the **Wave 4** distribution surface in the Personal Jarvis supply-chain hardening plan. Waves 1–3 (cosign + Sigstore Fulcio + offline Ed25519 + SLSA L3 + in-toto) all run *inside* `install-verify.sh`. Wave 4 secures the path that delivers `install-verify.sh` itself.

## Install

```bash
brew tap personal-jarvis/jarvis
brew install personal-jarvis-installer
personal-jarvis-installer
```

After `brew install`, the verifier is on your `PATH` as `personal-jarvis-installer`. Running it kicks off the full 12-stage signed install.

## Why this is more secure than `curl | bash`

The legacy quick-install path is:

```bash
curl -fsSL https://raw.githubusercontent.com/personal-jarvis/personal-jarvis/main/install-verify.sh | bash
```

That command trusts **GitHub's TLS chain** (~150 root CAs) to deliver the verifier intact. If any of the following happen, the verifier itself is substituted *before* it can verify anything else:

| Threat | What an attacker does | Wave 1–3 catches it? |
|---|---|---|
| DNS hijack of `raw.githubusercontent.com` | Routes the connection to an attacker-controlled host serving a malicious `install-verify.sh` | **No** — the bytes the user runs were never the real script |
| Mis-issued TLS certificate (CA compromise) | Presents a forged cert for `raw.githubusercontent.com`, serves malicious script | **No** — TLS chain is the trust ceiling |
| CDN edge tampering (CAPEC-438) | A compromised edge node mutates the script in flight | **No** — `curl` sees a "valid" 200 OK |
| Polyfill-style verifier substitution (2024) | Acquires hosting rights for the verifier path and swaps it for a near-identical malicious copy | **No** — the substituted script *is* the verifier |

In all four scenarios, the substituted `install-verify.sh` never runs the Wave 1–3 checks (or runs cosmetically-modified ones that always pass), and the whole supply-chain stack underneath is bypassed.

Homebrew closes that gap. `brew install` validates the formula via a **second, independent signing chain**: the tap is a git repository that you fetched via your local git's TLS + (optionally) commit signature verification, the Formula is a pinned `url` + `sha256` against an immutable release asset (not `master`/`HEAD`), and the resolved download is checksum-verified by Homebrew *before* execution. The attacker now has to compromise GitHub's TLS chain **and** flip the SHA-256 inside a committed-and-pushed Formula in this tap.

For the full Wave 4 threat model — including scenarios S-4 through S-8 (DNS hijack, TLS-CA compromise, CDN tampering, Polyfill-style substitution, post-quantum signature forgery) and the ML-DSA-65 PQ-migration plan — see:

- [`docs/supply-chain/wave4-distribution.md`](https://github.com/personal-jarvis/personal-jarvis/blob/main/docs/supply-chain/wave4-distribution.md)
- [`docs/supply-chain/threat-model.md` §9](https://github.com/personal-jarvis/personal-jarvis/blob/main/docs/supply-chain/threat-model.md)

## How this tap stays up to date

Each Personal Jarvis Wave 4+ release publishes a signed `install-verify.sh` asset under a pinned tag (e.g. `v0.4.0-supplychain-wave3`, `v0.5.0-wave4`). When a new release lands, this tap's Formula is updated to point at the new `url`, `version`, and `sha256`. The Formula MUST NEVER pull from `master`/`HEAD` — that would defeat the entire Wave 4 trust model (the immutable artifact is what's signed).

Every push to this tap runs `brew audit --strict` against the Formula on a `macos-latest` runner via [`.github/workflows/test-formula.yml`](./.github/workflows/test-formula.yml). A Formula that fails audit cannot land on `main`.

## Currently pinned

- `personal-jarvis-installer` → `v0.4.0-supplychain-wave3`
- SHA-256: `d81582569a828b99589b549a8d7544029dbd15a823fa5bba1d5abbc369bfed02`

## Issues, security reports, releases

This tap mirrors release decisions made in the main repo. File issues, security reports, and feature requests against [`personal-jarvis/personal-jarvis`](https://github.com/personal-jarvis/personal-jarvis), not this tap.

## License

MIT — see [`LICENSE`](./LICENSE). Same terms as the main repository.
