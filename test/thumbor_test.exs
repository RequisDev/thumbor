defmodule ThumborTest do
  use ExUnit.Case
  doctest Thumbor

  test "greets the world" do
    assert Thumbor.hello() == :world
  end
end
