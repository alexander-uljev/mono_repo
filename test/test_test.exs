defmodule MonoRepo.TestTest do
  use ExUnit.Case
  import MonoRepo.Test

  test "building test path list for target child" do
    assert build_test_paths("app00") == ["apps/app1/apps/app00/test"]
  end

  test "building test path list for entire tree" do
    assert build_test_paths() == [
      "apps/app0/test",
      "apps/app1/apps/app00/test"
    ]
  end

  test "building dependencies list" do
    assert build_deps() == [
      {:app0, path: "apps/app0"},
      {:app00, path: "apps/app1/apps/app00"}
    ]
  end

  test "assembling all children's configuration in 1 file" do
    build_config_files()
    actual = File.read!("config/config.exs")
    expected = "import Config\n\nconfig :app00,\n  par00: \"par00\"\n\nconfig :app0,\n  par0: \"val0\"\n\nimport_config \"\#{Mix.env()}.exs\"\n\n"
    assert actual == expected
    actual = File.read!("config/test.exs")
    expected = "import Config\n\nconfig :app00,\n  par00: \"overriden val00\"\n\nconfig :app0,\n  par0: \"overriden val0\"\n\n"
    assert actual == expected
  end

  test "raising in case of child not found or parent equals child" do
    assert_raise RuntimeError, fn -> build_test_paths("app_doesnt_exist") end
    assert_raise RuntimeError, fn -> build_test_paths("app_root") end
  end

end
