defmodule ExESDBGrpc.Application do
  @moduledoc """
  The ExESDBGrpc application.
  
  Starts the gRPC server and manages the application lifecycle.
  """
  
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting ExESDBGrpc application")
    
    # Get configuration
    port = Application.get_env(:ex_esdb_grpc, :port, 50051)
    enabled = Application.get_env(:ex_esdb_grpc, :enabled, true)
    
    children = if enabled do
      [
        {ExESDBGrpc.Server, [port: port]}
      ]
    else
      Logger.info("gRPC server disabled by configuration")
      []
    end

    opts = [strategy: :one_for_one, name: ExESDBGrpc.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
