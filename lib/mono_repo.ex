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

  ### Build

  Umbrella's documentation recommends keeping child application configuration in
  parent's one. If you feel like doing that, you can use
  `MonoRepo.Build.build_config_path/0` or `MonoRepo.Build.build_config_path/1`. If
  your application is deeply nested, it can be tedious and error prone to type
  dots in the path to a parent app. Consider typing *build_config_path()* instead of
  *"../../../../../../config/config.exs"*. Personally I prefer to have application's
  configuration at hands. For releasing a build a separate configuration file can
  be declared.

  Most of the times you'll want to keep all the dependencies and build artefacts
  at one place to avoid duplicating, version mismatching and curly paths manual
  searches. You can do so by using `MonoRepo.Build.build_deps_path/0` and
  `MonoRepo.Build.build_path/0`.

  ### Test

  Testing all the folded applications at any level made possible by
  `MonoRepo.Test.build_test_paths/0`. Assign your *:test_paths* key in the root
  umbrella application to build_test_paths() and running 'mix test' will run all
  tests in all child applications. Step one level into apps folder and run it
  again to get -1 level of applications to test.

  If you use *:apps_path* key in your `Mix.Project` declaration, testing won't be
  available, even direct calls to test files won't work. The workaround is to have
  a separate *mix.exs* file or to comment out the *:apps_path* line meanwhile testing.

  Testing requires applications and their dependencies to be started. In order
  to do that, use `build_deps/0` function of this module as a value of *:deps* key
  . It will load and start all applications prior testing.

  ### Release

  Release does not hack or alter Mix.Release functionality.
  To make a release you must describe it in *rel/definitions.exs* following
  instructions in `MonoRepo.Release` module. *rel/"release name".exs* must hold
  a regular application configuration specific for your release. rel/mix.exs must
  declare a MixProject suitable for releasing: *:deps* key must be set to
  `MonoRepo.Release.build_deps/0` and *:releases* - to
  `MonoRepo.Release.build_releases/0`, *:config_path* to
  `MonoRepo.Release.build_config_path/0` as a compile-time configuration. This way
  your app file will get only necessary arguments and your VM won't get rebooted
  after configuration loading unless you use releases.exs configuration as well.
  If you need run-time configuration, release.exs will be searched and loaded by
  `Mix.Release`. If you've got any other dependencies, you can define them in
  *deps/0* as usual and concatenate that list on release dependencies, like that
  : `deps: deps() ++ build_deps()` .

  *mix.exs* sample:
  ```elixir
  ...
  import MonoRepo.Release
  ...
  def project do
    [
      ...
      config_path: build_config_path(),
      deps: build_deps(),
      releases: build_releases()
    ]
  end
  ...
  ```
  ### Using

  `MonoRepo` is not a part of the mix application, so it is not loaded at the
  moment when mix.exs is being read. There are two ways of fixing that:
  1. append `MonoRepo`'s beam files' path before making calls to it. Use `Code`
  module:
  ```elixir
  true = Code.append_path("_build/${env}/lib/mono_repo/ebin")
  ```
  So the :mono_repo dependency must be compiled before doing this.

  2. Put `MonoRepo` codes under `Mix.Project` namespace, compile them, copy to
  mix lib folder(`/usr/lib/elixir/lib/mix/ebin/` on my machine) and add alien
  modules to modules list in `mix.app`. This is dirty and unrecommended but
  effective.
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
