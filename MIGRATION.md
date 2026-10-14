# Migrating from Thousand Island to Hell

This fork is based on upstream commit
`e3eb2a7a05f98d79436abcefd8c954da2f8b05c0` (upstream version `1.5.0`). The first
Hell package was `0.1.0`, published locally by the fork maintainer. Version
`0.1.1` uses a gated manual workflow for publication. Historical Thousand Island releases
remain upstream releases.

The migration changes project identities without changing socket behavior,
transport options, default values, lifecycle callbacks, timeout handling,
supervision strategies or cleanup. There are no compatibility aliases or shims.

## Dependencies and application identity

Hell requires Elixir `>= 1.18.0`, replacing the upstream `~> 1.13` requirement.
Upgrade older consuming toolchains before migrating; dependency versions remain
unchanged.

Replace the `:thousand_island` dependency with `{:hell, "~> 0.1.1"}` after the
next release is published. Until then, use the available `0.1.0` package, a local
path dependency or a reviewed commit from `gsmlg-dev/hell` as shown in
[README.md](README.md). The canonical `v0.1.1` tag is an alternative once created.
Do not substitute an unrelated package or publish to `thousand_island`.

Replace `ThousandIsland` and `ThousandIsland.*` with `Hell` and `Hell.*` throughout
application source, tests, examples, behaviours, `use` statements, `@impl`
annotations, structs, types, transport references and supervision children:

```elixir
children = [
  {Hell, port: 1234, handler_module: MyApp.ConnectionHandler}
]
```

Update explicit application startup/dependency declarations to `:hell`, including
`extra_applications`, release configuration and application environment entries
previously keyed by `:thousand_island`. The library itself has no application
environment reads or writes; server options continue to be supplied to
`Hell.start_link/1` or its child specification.

Any dependency compiled against `ThousandIsland` must also be migrated or replaced
with a compatible fork. For example, upstream Bandit refers to Thousand Island;
changing only the direct dependency name does not migrate that integration.
Regenerate the consuming application's lockfile as needed for its dependency
change. Remove stale build products in that consuming checkout (for example,
`mix clean`) and rebuild the application and affected dependencies. Restart
running nodes with the migrated application; no live upgrade compatibility is
provided between the former modules and Hell.

## Telemetry and logging

Change telemetry subscriptions from `[:thousand_island | suffix]` to
`[:hell | suffix]`. All event suffixes, measurements, metadata keys and structures,
span relationships and emission timing are preserved. For example:

```elixir
:telemetry.attach(
  "my-hell-connections",
  [:hell, :connection, :start],
  &MyApp.Telemetry.handle_event/4,
  nil
)
```

Use `Hell.Logger` to attach or detach built-in logging. Its telemetry handler IDs
are now `"Elixir.Hell.Logger.error"`, `"Elixir.Hell.Logger.info"`,
`"Elixir.Hell.Logger.debug"` and `"Elixir.Hell.Logger.trace"` because they are
derived from the module name. Update tooling that explicitly refers to those IDs.
Logger messages still render the same event, metadata and measurement structure;
the event prefix and embedded renamed modules identify Hell. The library defines
no separate application-specific Logger metadata keys.

## Supervisors and process labels

The public child specification's generated ID changes from
`{ThousandIsland, reference}` to `{Hell, reference}`. Update any tooling or
supervision code matching that module identity. Generated module-based child IDs
also reflect the renamed modules. Explicit role IDs (`:listener`,
`:acceptor_pool_supervisor`, `:shutdown_listener` and `"acceptor-N"`) are unchanged.

On supported Elixir versions with OTP 27+, process-label tuples start with
`:hell` instead of `:thousand_island`. Their role atoms, nested structure and
values are otherwise unchanged, apart from module identities. The existing
no-op behavior remains on OTP 26, which lacks process-label support; Elixir
versions below 1.18 are no longer supported.

## Custom handler implementations

Handlers built with `use Hell.Handler` receive the renamed internal readiness
message automatically. If you implement the lower-level handler startup protocol
yourself, change the received message atom from `:thousand_island_ready` to
`:hell_ready`:

```elixir
{:hell_ready, raw_socket, handler_config, acceptor_span, start_time}
```

Tuple layout, connection ownership transfer, handshake responsibilities and
callback behavior are unchanged. See [Hell.Handler](https://github.com/gsmlg-dev/hell/blob/main/lib/hell/handler.ex) for the
complete custom-handler contract. Error atoms and shutdown reasons are unchanged.

## Documentation and release

Source paths are `lib/hell.ex`, `lib/hell/**` and `test/hell/**`. Update links,
configuration, build tooling, package references and dashboards to the fork.
Published documentation is available for [Hell 0.1.0 on
HexDocs](https://hexdocs.pm/hell/0.1.0/). The next documentation destination is
[Hell 0.1.1](https://hexdocs.pm/hell/0.1.1/), available after workflow publication.
Build local documentation with `mix docs`.
[CHANGELOG.md](CHANGELOG.md) deliberately retains historical upstream module,
telemetry and release names. The [LICENSE](https://github.com/gsmlg-dev/hell/blob/main/LICENSE) retains all MIT terms and the upstream copyright notice,
adding copyright (c) 2026 GSMLG Limited for Hell fork contributions.

Version `0.1.1` requires workflow validation and explicit publication through
the gated flow described in [RELEASE.md](RELEASE.md). These migration instructions
do not imply that its publication or remote validation has completed.
