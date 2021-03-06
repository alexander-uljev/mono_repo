defmodule MonoRepo do
  @moduledoc """
  The MonoRepo library offers you a pattern of developing your applications in a
  mono repository and a set of functions to do it easily.

  With mono repo pattern your umbrella applications can nest other mono or umbrella
  applications. The library is split in 3 modules named after application
  lifecycle phases: Build, Test, Release. For specific functionality documentation
  please refer to corresponding module docs.

  ### Root application

  It is the top-level application which must be an umbrella application. It is
  recommended to use empty string("") as *:apps_path* value to avoid dependencies
  decla ration issues.

  ### Parent application

  Any linked application that is closer to the project's root application is a
  parent application. /1 functions from `MonoRepo.Build` module can be used to
  target them if you want to keep common configuration or dependencies in parent's
  folder instead of the root one.

  ### Child application

  Any linked application that is further from the project's root application is
  a child application. Child applications can be developed as standalone apps
  except for the mix.exs could be set to use root's/parent's folders for keeping
  dependencies and build artefacts.

  Applications should be nested in parent's apps folders. For example: "app0/
  apps/app1/apps/app2".

  ### Using

  `MonoRepo` is not a part of the mix application, so it is not loaded at the
  moment when mix.exs is being read. There are two ways of fixing that:
  1. append `MonoRepo`'s beam files' path before making calls to it. Use `Code`
  module:
  ```elixir
  true = Code.append_path("_build/dev/lib/mono_repo/ebin")
  ```
  Be sure the :mono_repo dependency is compiled before using any of it's modules
  .

  2. Put `MonoRepo` codes under `Mix.Project.MonoRepo` namespace, compile them,
  copy to mix lib folder(`/usr/lib/elixir/lib/mix/ebin/` on my machine) and add
  alien modules to modules list in `mix.app`. After those manipulations, you
  would be able to import `MonoRepo` modules. This is dirty and unrecommended but
  very convinient and effective.

  ### Build

  Most of the times you'll want to keep all the dependencies and build artefacts
  at one place to avoid duplicating, version mismatching and curly paths manual
  searches. You can do so by:

  1. Assigning *:build_path* to `MonoRepo.Build.build_path/0`.
  2. Assigning *:deps_path*  to `MonoRepo.Build.build_deps_path/0`.
  3. Assigning ":lockfile" to `MonoRepo.Build.build_lockfile_path/0`.

  Umbrella's documentation recommends keeping child application configuration in
  parent's one. If you feel like doing that, you can use
  `MonoRepo.Build.build_config_path/0` or `MonoRepo.Build.build_config_path/1`. If
  your application is deeply nested, it can be tedious and error prone to type
  dots in the path to a parent app. Consider typing *build_config_path()* instead of
  *"../../../../../../config/config.exs"*. Personally I prefer to have application's
  configuration at hands. For releasing a build a separate configuration file is
  declared.

  ### Test

  It is possible to run all children's tests at once by proper using
  `MonoRepo.Test`'s module's functions. The general recomendation is to use the
  root level project folder mainly for testing purposes.

  1. Build a united configuration by running `MonoRepo.Test.build_config_files()`.
  This will traverse the root application's tree and copy all *config.exs* and
  *test.exs* configuration files into two single files at *./config* path.
  `MonoRepo.Test.build_test_paths/0`.
  2. Assign *:test_paths* key in the root application to
  `MonoRepo.Test.build_test_paths/0`.
  3. Assign *:deps* key to `MonoRepo.Test.build_deps/0`. If you need to define
  other dependencies, you can do it in a standard way within *deps/0* function
  and concatenate both lists with `++` operator.

  Now run 'mix test' to run all tests in all child applications. Step one level
  into apps folder, repeat the setup and run it again to get -1 level of
  applications to test.

  If you use *:apps_path* key in your `Mix.Project` declaration, testing won't be
  available, even direct calls to test files won't work. The workaround is to have
  a separate *mix.exs* file or to comment out the *:apps_path* line meanwhile testing.

  Testing requires applications and their dependencies to be started. That's why
  we use `build_deps/0` as value of *:deps* key.

  ### Release

  Release does not hack or alter Mix.Release functionality.
  To make a release you must describe it in *rel/definitions.exs* following
  instructions in `MonoRepo.Release` module. *rel/"release name".exs* must hold
  a regular application configuration specific for your release. *rel/mix.exs* must
  declare a MixProject suitable for releasing:
  1. *:deps* key must be set to `MonoRepo.Release.build_deps/0`
  2. *:releases* - to `MonoRepo.Release.build_releases/0`
  3.  *:config_path* to `MonoRepo.Release.build_config_path/0` as a compile-time
  configuration.
  This way your app file will get only necessary arguments and your VM won't get rebooted
  after configuration loading unless you use releases.exs configuration as well.
  Keep *mono_repo* as a dependency in release mix project file to avoid erasing
  it's beam files.

  If you need run-time configuration, release.exs will be searched in *config*
  folder and loaded by `Mix.Release`. If you've got any other dependencies, you
  can define them in *deps/0* as usual and concatenate that list on release
  dependencies, like that: `deps: deps() ++ build_deps()`.

  `MonoRepo.Release` uses release name command-line argument so **make sure you
   don't put any switches or arguments before the name**.

  *mix.exs* sample:
  ```elixir
  ...
  import MonoRepo.Release
  ...
  def project do
    [
      ...
      config_path: build_config_path(),
      deps: build_deps() ++ deps(),
      releases: build_releases()
    ]
  end

  defp deps do
    [
      {:mono_repo, path: "../mono_repo", only: [:dev, :prod], runtime: false},
    ]
  end
  ...

  ```
  """

  @typedoc """
  Child is an application atom which position is lower in a mono repo hierachy.
  """
  @type child :: atom()

  @typedoc """
  Parent is an application atom which position is higher in a mono repo hierachy
  .
  """
  @type parent :: atom()

  @typedoc """
  Root is an application atom which position is the highest in a mono repo
  hierachy.
  """
  @type root :: atom()

  @doc """
  Returns a version read from "version" file in application's root directory.

  The aim here is to avoid forgetting updating version in neither development
  mix.exs nor rel/mix.exs. The dev mix.exs should read from the file using this
  function as well.
  """
  @spec version() :: Version.version()

  def version() do
    "version"
    |> File.read!()
    |> String.trim_trailing()
  end
end
