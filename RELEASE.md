# Hell CI and release preparation

Hell targets `gsmlg-dev/hell`, OTP application `:hell` and the intended Hex package
`hell`. It is derived from Thousand Island; upstream history and historical tags
remain Thousand Island history. The upstream baseline was version `1.5.0`;
`mix.exs` now declares the first planned Hell version, `0.1.0`. This version
remains unpublished and does **not** announce a Hell release.

## Validation and supported toolchains

`ci.yml` checks compilation with warnings as errors, unused locked dependencies,
formatting, strict Credo, Dialyzer and documentation. `test.yml` runs the full
existing ExUnit suite separately. Machete is the suite's assertion dependency,
not a separate static-check command. All caches include Hell identity, toolchain
and architecture; workflows request only `contents: read` and cancel redundant
runs. Automatic retry and privileged cache-deletion workflows were removed.

The declared Elixir requirement is now `>= 1.18.0`; dependencies are unchanged.
The upstream delegated CI at
[`mtrudel/elixir-ci-actions@18c287f`](https://github.com/mtrudel/elixir-ci-actions/tree/18c287f5666c0873f6c8c585551b9416694a731c/.github/workflows)
effectively tested eight Linux combinations: Elixir `1.17.x` with OTP 26/27,
and `1.18.x` and `1.19.0` with OTP 26/27/28. Hell drops the two `1.17.x`
combinations to match the new minimum and tests these six pairs on each OS:

| Elixir | OTP |
| --- | --- |
| `1.18.x` | `26.x`, `27.x`, `28.x` |
| `1.19.0` | `26.x`, `27.x`, `28.x` |

These run on `ubuntu-24.04` and `macos-26` (ARM64).
Upstream's exclusions for `1.19.x` did not match its `1.19.0` matrix entry, so
removing those ineffective exclusions preserves the actual coverage. No claim
is made that every declared supported version is exercised by this matrix.

Runner/toolchain compatibility was inspected on 2026-10-14:

- Pinned [`setup-beam v1.24.1`](https://github.com/erlef/setup-beam/tree/54075bcc5e249e4758d363f27d099f55d843f124)
  documents macOS 26 on ARM64 with OTP 25–29. Its source resolves ARM64 through
  `aarch64-apple-darwin.csv` and uses `OTP-<version>-macos-arm64.tar.gz` builds;
  the OTP 26.2.5.15 ARM64 asset and current OTP 26–28 build listings were checked.
- [`runner-images@573fa3a`](https://github.com/actions/runner-images/blob/573fa3ad959907712ce8bf6a5f91ab82b03e7f2d/README.md)
  identifies `macos-26` as ARM64 and the newest stable macOS image. The test job
  verifies `RUNNER_ARCH=ARM64` and prints the resolved Elixir/OTP versions.
- The Hex Elixir build listing includes OTP 26/27/28 builds for current
  `1.18.x` and exact `1.19.0`. This inspection is
  compatibility evidence; remote CI on this migration has not been run.

Actions are pinned to inspected stable release commits: checkout v7.0.1,
cache v6.1.0, upload-artifact v7.0.2 and setup-beam v1.24.1.

## Local package and artifact tests

Run the existing validation commands with the unchanged dependency lock:

```sh
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
MIX_ENV=test mix compile --warnings-as-errors
mix deps.unlock --check-unused
mix credo --strict
mix dialyzer
mix test
mix docs
mix hex.build
bash scripts/artifact_smoke.sh hell-0.1.0.tar 0.1.0
```

The smoke script verifies the tarball's Hex package name, application and version,
then uses Hex's checksum-checked in-memory archive unpacker and writes only
regular files with safe relative paths. An isolated temporary Mix
consumer compiles the unpacked package with the already downloaded, locked
telemetry source from this checkout, without resolving different dependency
versions. It tests TCP echo, certificate-verified TLS echo through OTP `:ssl`,
and graceful shutdown callbacks, socket closure and server termination. It uses
only this repository's existing test certificate fixtures and removes its
temporary consumer on exit. These artifact tests supplement the existing suite.

`e2e.yml` is manual and downloads the exact `hell-VERSION.tar` asset from the
`vVERSION` GitHub release in `gsmlg-dev/hell`, then runs the same consumer tests.
A future Hell GitHub release must contain that asset before this remote workflow
can succeed. Historical upstream releases are not candidates for this workflow.

## Preparation and publication prerequisites

`release.yml` is a **build-only**, manual workflow. It neither changes versions nor
creates commits, tags or GitHub releases, and contains no publishing command or
publishing secret. It runs only when dispatched from `main` in `gsmlg-dev/hell`.
The input version must match `mix.exs`; `git_ref` must be `main` or the exact
`vVERSION` tag. The checker verifies repository metadata and the `hell` app/package
identities. Tag preparation additionally requires that tag to point at the
checked-out commit. Preparation from `main` works before any Hell tag exists and
reports the expected future tag. The workflow validates, builds documentation and
the Hex tarball, smoke-tests that tarball, and uploads reviewable candidate
artifacts only.

Before enabling any future publication flow, a maintainer must:

1. Review the planned `0.1.0` release and confirm its metadata and changes are
   ready. The version decision is recorded in `mix.exs`; no release exists yet.
2. Confirm permission to publish Hex package `hell`. A read-only lookup of
   `https://hex.pm/api/packages/hell` returned HTTP 404 (`Page not found`) on
   2026-10-14 at 13:15 UTC. This records apparent availability at that time;
   it does not reserve the name. Recheck it before setup; if occupied or
   unverified, keep publishing disabled and do not choose another name silently.
3. Review a trusted Hell commit and create its corresponding `vVERSION` tag in
   `gsmlg-dev/hell`. Upstream tags do not become Hell releases by inheritance.
4. Configure a protected release environment and a Hex API credential authorized
   for `hell` (normally `HEX_API_KEY`) only after explicit release authorization.
   No credentials or repository protection settings are configured by this task.
5. Require explicit publication approval and validate `github.repository`, the
   trusted tag/ref, the tag's commit, `mix.exs` version, artifact version, OTP app
   and Hex package name together immediately before publishing. A future publisher
   must reject pull-request code and mismatches and must never publish
   `thousand_island`. The current checker authorizes preparation only.
6. Attach the verified `hell-VERSION.tar` to the actual Hell GitHub release so the
   manual release-artifact e2e workflow can consume it.

No publishing trigger is enabled by this migration. A successful preparation run
is not a publication or a GitHub release.
