defmodule MonoRepo.BuildTest do
  use ExUnit.Case
  import MonoRepo.Build

  @moduledoc """
  Please run this particular file from app_root/apps/app1/apps/app00 folder.
  """

  test "returning building path for target parent app" do
    assert build_path("app1") == "../../app1/_build"
  end

  test "returning building path for root app" do
    assert build_path() == "../../../../app_root/_build"
  end

  test "raising in case build path can't be computed" do
    assert_raise RuntimeError, fn -> build_path("app_doesnt_exist") end
  end

  test "returning configuration path for target parent app" do
    assert build_config_path("app1") == "../../app1/config/config.exs"
  end

  test "returning configuration path for root app" do
    assert build_config_path() == "../../../../app_root/config/config.exs"
  end

  test "raising in case configuration path can't be computed" do
    assert_raise RuntimeError, fn -> build_config_path("app_doesnt_exist") end
  end

  test "returning deps path for target parent app" do
    assert build_deps_path("app1") == "../../app1/deps"
  end

  test "returning deps path for root app" do
    assert build_deps_path() == "../../../../app_root/deps"
  end

  test "raising in case deps path can't be computed" do
    assert_raise RuntimeError, fn -> build_deps_path("app_doesnt_exist") end
  end

  test "returning lockfile path for target parent app" do
    assert build_lockfile_path("app1") == "../../app1/mix.lock"
  end

  test "returning lockfile path for root app" do
    assert build_lockfile_path() == "../../../../app_root/mix.lock"
  end

  test "raising in case lockfile path can't be computed" do
    assert_raise RuntimeError, fn -> build_lockfile_path("app_doesnt_exist") end
  end

end
