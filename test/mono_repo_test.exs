defmodule MonoRepoTest do
  use ExUnit.Case
  doctest MonoRepo
  import MonoRepo
  
  test "returning version number from version file" do
    assert version() == "0.0.1"
  end

end
