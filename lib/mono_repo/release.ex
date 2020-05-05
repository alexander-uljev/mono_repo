defmodule MonoRepo.Release do
  @moduledoc """
  Release holds functions for building dependencies and releases list from custom configuration.

  For proper work you need to create a separate mix.exs, definition.exs and
  "release name".exs files in rel folder in project's root. Mix project
  configurations for development and for releasing with MonoRepo pattern are quite
  different, so we create a separate mix.exs for releases. definition.exs describes
  our releases using Config module. Root key of a configuration must be a release
  name. *:applications* attribute should be a list of applications' names in a
  specific format which will be passed by this module's functions. The valid
  format for app name is path/to/app. Be sure to avoid mentioning apps folders in
  your paths. For example if your app is nested like root_app/apps/app1/apps/app2,
  you should refer to it as app1/app2. All the other release options found
  in Mix.Release documentation can be passed as is. The last file we need is a
  "release name".exs. It's your compile-time configuration for your release. It
  should be used for *:config_path* attribute of mix project configuration. This way
  you can keep release-specific configuration nice and tidy and do not load
  unnecessary configuration attributes. To make a release use MIX_EXS environment
  variable set to the release MixProject file. `MonoRepo.Release` uses release name
  command-line argument so **make sure you don't put any switches or arguments
  before the name**. Usage:

  `MIX_EXS=rel/mix.exs mix release set0`

  *definitions.exs* sample:
  ```elixir
  import Config

  config :set0,
    applications: ["child0", "child1/child2"],
    strip_beams: false

  config :set1,
    applications: ~w(child3/child4/child5 child6/child7)
  ```
  """

  @doc """
  Returns release-specific configuration file path.

  It relies on release name from passed arguments. So NIX_EXS=rel/mix.exs mix
  release set0 will assign config_path to rel/set0.exs in case mentioned mix.exs
  uses this module's config_path function.
  """
  @spec build_config_path() :: Path.t()

  def build_config_path() do
    config = get_release_name() <> ".exs"
    Path.join("rel", config)
  end

  @doc """
  Builds a list of dependencies from rel/definitions.exs.

  All dependencies will get released the same way your main application will.
  This way you can add any application or nested application at any level to
  your final release.
  """
  @spec build_deps() :: [{atom(), path: String.t()}]

  def build_deps() do
    get_release_atom()
    |> read_config()
    |> Keyword.get(:applications)
    |> build_deps()
  end

  @doc """
  Builds a standard releases list with all applications set to permanent mode.

  Other modes are not yet supported. Requires a rel/definitions.exs to read
  release setup. This function must always be used since there is no default
  release, so building one requires a name and that requires a release
  declaration.
  """
  @spec build_releases() :: [{atom(), [applications: [{atom(), :permanent}]]}]

  def build_releases() do
    name = get_release_atom()
    config = read_config(name)
    {apps, opts} = Keyword.pop(config, :applications)
    apps = build_release_apps(apps)
    [{name, [{:applications, apps} | opts]}]
  end

  ### PRIVATE ###

  @spec get_release_name() :: String.t()
  defp get_release_name() do
    System.argv()
    |> Enum.at(1)
  end

  @spec get_release_atom() :: atom()
  defp get_release_atom do
    get_release_name() |> String.to_atom()
  end

  @spec read_config(atom()) :: keyword()
  defp read_config(release) do
    "rel"
    |> Path.join("definitions.exs")
    |> Config.Reader.read!()
    |> Keyword.get(release)
  end

  @spec build_deps([String.t()]) :: [{atom(), path: String.t()}]
  defp build_deps(apps) do
    for app <- apps, do: build_dep(app)
  end

  @spec build_dep(String.t()) :: {Application.app(), path: Path.t()}
  defp build_dep(app) do
    name = build_app_name(app)
    path = build_path(app)
    {name, path: path}
  end

  @spec build_path(String.t()) :: Path.t()
  defp build_path(app) when is_binary(app) do
    app
    |> String.split("/")
    |> build_path()
  end

  @spec build_path([String.t()]) :: Path.t()
  defp build_path(apps) when is_list(apps) do
    Enum.reduce(apps, "", fn(app, acc) ->
      path = Path.join("apps", app)
      Path.join(acc, path)
    end)
  end

  @spec build_app_name(String.t()) :: Application.app()
  defp build_app_name(app) do
    app
    |> String.split("/")
    |> List.last()
    |> String.to_atom()
  end

  @spec build_release_apps([String.t()]) :: [{Application.app(), :permanent}]
  defp build_release_apps(apps) do
    for app <- apps do
      name = build_app_name(app)
      {name, :permanent}
    end
  end

end
