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

  test "raising in case of child not found or parent equals child" do
    assert_raise RuntimeError, fn -> build_test_paths("app_doesnt_exist") end
    assert_raise RuntimeError, fn -> build_test_paths("app_root") end
  end

end
