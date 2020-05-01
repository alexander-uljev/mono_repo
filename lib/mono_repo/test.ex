defmodule MonoRepo.Test do
  @moduledoc """
  This module holds a set of functions to build test paths for your mix project
  configuration.

  Instead of manually creating lists of folded applications` paths like
  *"apps/app0/apps/app1/apps/app2/test"* use functions from this module.
  """


  @doc """
  Builds a list of paths to test directories of all the applications found in
  apps directory recursively.

  It means that in case an application is apps directory includes apps directory,
  all those apps' test directories will be included.
  """
  @spec build_test_paths() :: [String.t()]

  def build_test_paths() do
    get_apps_paths()
    |> add_apps_of_app()
    |> List.flatten()
    |> add_test_dir()
  end

  @doc """
  Builds a list of paths to test directories of all the applications found in
  apps directory recursively until it finds the first match.

  Behaves in simmilar fashion to it's */0* implementation.

  """
  @spec build_test_paths(child :: MonoRepo.child()) :: [String.t()]

  def build_test_paths(child) do
    path =
      child
      |> get_child_path!()
      |> add_test_dir
    [path]
  end

  @doc """
  Builds dependencies list to support testing.

  This function **MUST** be used together with `build_test_paths/0` in order to
  start all applications before tests evaluation.
  """
  @spec build_deps() :: [{Application.app(), path: Path.t()}]

  def build_deps() do
    paths = get_apps_paths()
     |> add_apps_of_app()
     |> List.flatten()
    for path <- paths do
      name = get_app_name(path)
      {name, path: path}
    end
  end

  ### PRIVATE ###

  @spec get_apps_paths() :: [String.t()]
  defp get_apps_paths() do
    list_relative_paths("apps")
  end

  @spec get_apps_paths(String.t()) :: [String.t()]
  defp get_apps_paths(path) do
    [path, "apps"]
    |> Path.join()
    |> list_relative_paths()
  end

  @spec add_apps_of_app([String.t()]) :: [String.t()]
  defp add_apps_of_app(paths) do
    for path <- paths, reduce: [] do
      acc ->
        if leaf?(path) do
          [path | acc]
        else
          path =
            path
            |> get_apps_paths()
            |> add_apps_of_app()
          [path | acc]
        end
    end
  end

  @spec add_test_dir([String.t()]) :: [String.t()]
  defp add_test_dir(paths) when is_list(paths) do
    for path <- paths, do: append_test_dir(path)
  end

  @spec add_test_dir(String.t()) :: String.t()
  defp add_test_dir(path) when is_binary(path) do
    append_test_dir(path)
  end

  @spec append_test_dir(String.t()) :: String.t()
  defp append_test_dir(path), do: Path.join(path, "test")

  @spec leaf?(String.t()) :: boolean()
  defp leaf?(path) do
    false ==
      path
      |> Path.join("apps")
      |> File.exists?()
  end

  @spec get_app_name(Path.t()) :: Application.app()
  defp get_app_name(path) do
    path
    |> Path.split()
    |> List.last()
    |> String.to_atom()
  end

  @spec get_child_path!(MonoRepo.child()) :: String.t() | RuntimeError
  defp get_child_path!(child) do
    path = get_apps_paths() |> search_child(child)
    if path == nil do
      raise RuntimeError, "app #{child} not found"
    else
      path
    end
  end

  @spec search_child([String.t()], MonoRepo.child()) :: String.t() | nil
  defp search_child(paths, child) do
    Enum.find_value(paths, fn(path) ->
      cond do
        is_target?(path, child) ->
          path
        not leaf?(path) ->
          path
          |> get_apps_paths()
          |> search_child(child)
        true ->
          false
      end
    end)
  end

  @spec is_target?(String.t(), MonoRepo.child()) :: boolean()
  defp is_target?(path, child) do
    child ==
      path
      |> Path.split()
      |> List.last()
  end

  @spec list_relative_paths(String.t()) :: [String.t()]
  defp list_relative_paths(target) do
    target
    |> File.ls!()
    |> Enum.map(& Path.absname(&1, target))
  end

end
