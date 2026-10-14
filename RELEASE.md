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

## Manual preparation and publication

`release.yml` is manual. Its `publish` boolean defaults to `false`; preparation
from `main` remains available without publishing or a release tag. Both modes
validate the repository, package/application identities and exact version, then
compile, check formatting, run the existing suite, build docs and the Hex package,
smoke-test the tarball and upload candidate artifacts. Neither mode changes
versions, creates commits/tags/GitHub releases or pushes Git refs.

For the first Hell publication, dispatch this workflow **from `main`** in
`gsmlg-dev/hell` with `version=0.1.0`, `git_ref=v0.1.0` and `publish=true` after the
trusted tag is created. Selecting `publish=true` is the explicit publication
opt-in; `git_ref=main` cannot publish. The tag must point at the checked-out commit,
which must be an ancestor of `origin/main`. Repository, workflow event/ref,
source URL, app/package name, version/tag and built tarball metadata are validated
again immediately before publication. No pull-request or automatic tag/push
trigger can access this publishing path.

The final publishing step uses only the existing organization-provided
`HEX_API_KEY` secret available to this repository. That credential must authorize
public Hex package creation/publication and documentation upload. It is exposed
only to that gated step, never printed, and no keys, authentication profiles,
GitHub environments or repository security settings are configured by the
workflow. A maintainer may add protected release-environment controls separately;
they are not an additional prerequisite imposed by this release implementation.

Immediately before first publication, a read-only HTTPS lookup of
`https://hex.pm/api/packages/hell` must return HTTP 404. The earlier lookup returned
404 on 2026-10-14 at 13:15 UTC, without reserving the name. Occupied names, network
failures or unverified responses abort publication; no alternative package name
is chosen. This first-package flow also rejects an occupied name on reruns; any
later release or documentation-only recovery needs a deliberate ownership-aware
flow rather than overwriting an existing package silently.

After these gates pass, `mix hex.publish --yes` publishes **both the package and
its documentation** using the installed Hex CLI. It has no replacement or private
organization flag, and can never target `thousand_island`. Successful preparation
alone is not publication; verify the publish-step result and public Hex/HexDocs
availability before claiming delivery. Historical upstream tags remain Thousand
Island releases.

The actual Hell GitHub release should attach the verified `hell-VERSION.tar`
asset so `e2e.yml` can consume it. GitHub release/tag creation remains a separate
maintainer action; this workflow requests only `contents: read`.
