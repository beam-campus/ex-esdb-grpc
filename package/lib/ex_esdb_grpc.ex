defmodule ExESDBGrpc do
  @moduledoc """
  ExESDBGrpc provides a gRPC API server for ExESDB event store clusters.
  
  This package offers an EventStore-compatible gRPC API that allows external
  clients to read and write events, subscribe to streams, and perform other
  event store operations over gRPC.
  
  ## Features
  
  - EventStore-compatible gRPC API
  - Stream reading and writing
  - Event subscriptions with streaming
  - Health checks
  - Transaction support
  - Stream management operations
  
  ## Usage
  
  Add to your supervision tree:
  
      children = [
        {ExESDBGrpc.Server, [port: 50051]}
      ]
  
  Or configure in your application:
  
      config :ex_esdb_grpc,
        enabled: true,
        port: 50051
  
  ## Dependencies
  
  This package requires `ex_esdb_gater` for core event store functionality.
  """
  
  @doc """
  Returns version information.
  """
  def version do
    Application.spec(:ex_esdb_grpc, :vsn) |> to_string()
  end
  
  @doc """
  Checks if the gRPC server is running.
  """
  def server_running? do
    case GenServer.whereis(ExESDBGrpc.Server) do
      nil -> false
      _pid -> true
    end
  end
  
  @doc """
  Gets the current server configuration.
  """
  def server_info do
    if server_running?() do
      GenServer.call(ExESDBGrpc.Server, :info)
    else
      {:error, :server_not_running}
    end
  end
end
