defmodule MonoRepo.Build do
  @moduledoc """
  This module holds a set of search path functions for convinient building of
  paths to parent applications.

  These functions take a parent application's name as argument and return a
  string of unexpanded path to parent application relative to caller's directory
  . For example: if *root_app* includes *child_app* as tier 1 child then calling
  any function will return *"../../specific_path"*.
  """

  import File, only: [exists?: 1]

  @doc """
  Searches for the root or parent application and returns a path to it's build
  directory.

  Builds a path to parent application's build directory(_build) or raises a
  RuntimeError. The first argument is an application's name as a string, the
  second one is a path to be appended to parent's application path.
  """
  @spec build_path(parent :: MonoRepo.parent() | :root, target :: String.t())
  :: Path.t()

  def build_path(parent \\ :root, target \\ "_build") do
    get_path(parent, target)
  end

  @doc """
  Searches for the root or parent application and returns a path to it's
  configuration directory.

  The first argument is an application's name as a string, the second one is a
  path to be appended to parent's application path. Raises `RuntimeError` in
  case the path can't be resolved.
  """
  @spec build_config_path(parent :: MonoRepo.parent() | :root, target :: Path.t())
  :: Path.t()

  def build_config_path(parent \\ :root, target \\ Path.join("config", "config.exs"))
  do
    get_path(parent, target)
  end

  @doc """
  Searches for the root or parent application and returns a path to it's
  dependencies directory.

  Builds a path to root/parent application's dependencies directory(deps) or
  raises a `RuntimeError`. The first argument is an application's name as a
  string, the second one is a path to be appended to parent's application path.
  """
  @spec build_deps_path(parent :: MonoRepo.parent() | :root, target :: String.t())
  :: Path.t()

  def build_deps_path(parent \\ :root, target \\ "deps") do
    get_path(parent, target)
  end

  @doc """
  Searches for the root or parent application and returns a path to it's
  lockfile path directory.

  Builds a path to root/parent application's lockfile(mix.lock) or raises a
  RuntimeError. The first argument is an application's name as a string, the
  second one is a path to be appended to parent's application path.
  """
  @spec build_lockfile_path(parent :: MonoRepo.parent() | :root,
                           target :: String.t())
                                  :: Path.t()

  def build_lockfile_path(parent \\ :root, target \\ "mix.lock") do
    get_path(parent, target)
  end

  ### PRIVATE ###

  @spec get_path(MonoRepo.parent() | :root, String.t()) :: Path.t()
  defp get_path(:root, target) do
    :root
    |> get_parent_path!()
    |> append_path(target)
    |> trim_dot_dir()
  end

  defp get_path(parent, target) do
    parent
    |> match_parent_path!()
    |> append_path(target)
    |> trim_dot_dir()
  end

  @spec get_parent_path!(:root) :: Path.t()
  defp get_parent_path!(:root) do
    if path = get_parent_path(:current) do
      get_parent_path(path)
    else
      no_parent!()
    end
  end

  @spec get_parent_path(:current) :: Path.t() | nil
  defp get_parent_path(:current) do
    parent = parent_path(".")
    parent_apps = parent_apps_path(parent)
    if exists?(parent_apps) do
      parent
    else
      nil
    end
  end

  @spec get_parent_path(Path.t()) :: Path.t()
  defp get_parent_path(path) do
    parent = parent_path(path)
    parent_apps = parent_apps_path(parent)
    if exists?(parent_apps) do
      get_parent_path(parent)
    else
      app_name = get_parent_name(path)
      append_path(path, app_name)
    end
  end

  @spec match_parent_path!(String.t()) :: Path.t()
  defp match_parent_path!(target) do
    if parent = match_parent_path(target) do
      parent
    else
      no_parent!(target)
    end
  end

  @spec match_parent_path(String.t()) :: Path.t()
  defp match_parent_path(target) do
    parent_path = parent_path(".")
    match_parent_path(parent_path, target)
  end

  @spec match_parent_path(Path.t(), String.t()) :: Path.t() | nil
  defp match_parent_path(parent_path, target) do
    parent_apps = parent_apps_path(parent_path)
    if exists?(parent_apps) do
      parent_name = get_parent_name(parent_path)
      if parent_name != target do
        parent_path = parent_path(parent_path)
        match_parent_path(parent_path, target)
      else
        app_name = get_parent_name(parent_path)
        append_path(parent_path, app_name)
      end
    else
      nil
    end
  end

  @spec get_parent_name(Path.t()) :: String.t()
  defp get_parent_name(parent_path) do
    parent_path
    |> Path.expand()
    |> Path.split()
    |> List.last()
  end

  @spec parent_path(Path.t()) :: Path.t()
  defp parent_path(path) do
    parent = Path.join(~w(.. ..))
    Path.join(path, parent)
  end

  @spec parent_apps_path(Path.t()) :: Path.t()

  defp parent_apps_path(path), do: Path.join(path, "apps")

  @spec append_path(Path.t(), Path.t()) :: Path.t()
  defp append_path(path1, path2) do
    Path.join(path1, path2)
  end

  @spec trim_dot_dir(Path.t()) :: Path.t()

  defp trim_dot_dir(path), do: String.trim_leading(path, "./")

  @spec no_parent!() :: no_return()
  defp no_parent!() do
    raise RuntimeError, """
      Current working directory doesn't have a parent umbrella aplication.
    """
  end

  @spec no_parent!(String.t()) :: no_return()
  defp no_parent!(target) do
    raise RuntimeError, """
      Could not find a target parent application for: #{target}
    """
  end

end
