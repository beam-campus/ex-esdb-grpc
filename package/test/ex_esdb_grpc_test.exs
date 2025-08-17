defmodule ExEsdbGrpcTest do
  use ExUnit.Case
  doctest ExEsdbGrpc

  test "greets the world" do
    assert ExEsdbGrpc.hello() == :world
  end
end
