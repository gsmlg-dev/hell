version = System.fetch_env!("RELEASE_VERSION")
ref = System.fetch_env!("RELEASE_REF")
config = Mix.Project.config()
package = Keyword.get(config, :package, [])
package_name = Keyword.get(package, :name, Atom.to_string(config[:app]))

unless System.get_env("GITHUB_REPOSITORY", "gsmlg-dev/hell") == "gsmlg-dev/hell" and
         config[:source_url] == "https://github.com/gsmlg-dev/hell" and
         config[:app] == :hell and package_name == "hell" do
  raise "release repository, OTP application and Hex package must identify gsmlg-dev/hell"
end

unless Regex.match?(~r/\A[0-9]+\.[0-9]+\.[0-9]+\z/, version) and config[:version] == version do
  raise "release version must exactly match mix.exs; no automatic version bump is performed"
end

tag = "v#{version}"

case ref do
  "main" ->
    IO.puts("Preparing Hell #{version}; its future release tag must be #{tag}")

  ^tag ->
    {tags, 0} = System.cmd("git", ["tag", "--points-at", "HEAD"])

    unless tag in String.split(tags, "\n", trim: true) do
      raise "release tag #{tag} must point to the checked-out commit"
    end

    IO.puts("Validated Hell #{version} at tag #{tag}")

  _ ->
    raise "git_ref must be main or #{tag}"
end

IO.puts("Publication is disabled; this check authorizes preparation only")
