defmodule MonoRepo.ReleaseTest do
  use ExUnit.Case
  import MonoRepo.Release

  test "returning release specific configuration path" do
    System.argv(~w(release set0))
    assert build_config_path() == "rel/set0.exs"
  end

  test "returning dependencies list build " do
    System.argv(~w(release set0))
    assert build_deps() == [
      {:app0,  path: "apps/app0"},
      {:app00, path: "apps/app1/apps/app00"}]
  end

  test "returning release list build " do
    System.argv(~w(release set0))
    assert build_releases() == [set0:
      [applications:
        [app0:  :permanent,
         app00: :permanent],
       strip_beams: false]]
  end

end
