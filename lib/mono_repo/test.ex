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
    build_apps_paths() |> add_test_dir()
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
    paths = build_apps_paths()
    for path <- paths do
      name = get_app_name(path)
      {name, path: path}
    end
  end

  @doc """
  Assembles all configuration files of all application's children into one.

  Runs this procedure for cofig.exs and test.exs files found in children's *config*
  folders and writes assembled config.exs and test.exs to application's root
  folder, to *conig* subfolder.
  """
  @spec build_config_files() :: :ok

  def build_config_files() do
    paths = build_apps_paths() |> add_config_dir()
    paths
    |> build_config_exs()
    |> write_config_exs()
    paths
    |> build_test_exs()
    |> write_test_exs()
  end

  ### PRIVATE ###

  @spec build_apps_paths() :: [Path.t()]
  defp build_apps_paths do
    get_apps_paths()
    |> add_apps_of_app()
    |> List.flatten()
  end

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

  @spec add_config_dir([Path.t()]) :: [Path.t()]
  defp add_config_dir(paths) do
    for path <- paths, do: Path.join(path, "config")
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

  @spec build_config_exs([Path.t()]) :: IO.chardata()
  defp build_config_exs(paths) do
    paths
    |> collect_config_exs()
    |> prepend_conf_import()
    |> append_conf_import()
  end

  @spec build_test_exs([Path.t()]) :: IO.chardata()
  defp build_test_exs(paths) do
    paths
    |> collect_test_exs()
    |> prepend_conf_import()
  end

  @spec collect_config_exs([Path.t()]) :: IO.chardata()
  defp collect_config_exs(paths) do
    for path <- paths, reduce: [] do
      acc ->
        path = Path.join(path, "config.exs")
        {status, data} = File.read(path)
        if status == :ok do
          data =
            data
            |> delete_first_line()
            |> delete_last_line()
            |> append_double_new_line()
          [data | acc]
        else
          acc
        end
    end
  end

  @spec append_conf_import(IO.chardata()) :: IO.chardata()
  defp append_conf_import(data) do
    line = ~S/import_config "#{Mix.env()}.exs"/
    data ++ [line, "\n\n"]
  end

  @spec prepend_conf_import(IO.chardata()) :: IO.chardata()
  defp prepend_conf_import(data) do
    line = "import Config\n\n"
    [line | data]
  end

  @spec collect_test_exs([Path.t()]) :: IO.chardata()
  defp collect_test_exs(paths) do
    for path <- paths, reduce: [] do
      acc ->
        path = Path.join(path, "test.exs")
        {status, data} = File.read(path)
        if status == :ok do
          data =
            data
            |> delete_first_line()
            |> append_double_new_line()
          [data | acc]
        else
          acc
        end
    end
  end

  @spec delete_first_line(String.t()) :: String.t()
  defp delete_first_line(data) do
    line0 = ~s/import Config/
    line1 = ~s/use Mix.Config/
    data
    |> delete_line(line0)
    |> delete_line(line1)
    |> String.trim_leading()
  end

  @spec delete_last_line(String.t()) :: String.t()
  defp delete_last_line(data) do
    line = ~S/import_config "#{Mix.env()}.exs"/
    delete_line(data, line)
  end

  @spec append_double_new_line(String.t()) :: String.t()
  defp append_double_new_line(data) do
    data
    |> String.trim_trailing()
    |> append_new_line()
    |> append_new_line()
  end

  @spec append_new_line(String.t()) :: String.t()

  defp append_new_line(data), do: Enum.join([data, "\n"])

  @spec delete_line(String.t(), String.t()) :: String.t()

  defp delete_line(data, line), do: String.replace(data, line, "")

  @spec write_config_exs(IO.chardata()) :: :ok
  defp write_config_exs(data) do
    write_file!("config/config.exs", data)
  end

  @spec write_test_exs(IO.chardata()) :: :ok
  defp write_test_exs(data) do
    write_file!("config/test.exs", data)
  end

  @spec write_file!(Path.t(), IO.chardata()) :: :ok
  defp write_file!(path, data) do
    File.write!(path, data, [:utf8])
  end
end
