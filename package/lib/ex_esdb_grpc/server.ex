defmodule ExESDBGrpc.Server do
  @moduledoc """
  gRPC server for ExESDB event store clusters.

  This GenServer manages the lifecycle of the gRPC server and provides
  an interface for starting, stopping, and monitoring the server.
  """

  use GenServer
  require Logger

  def start_link(opts \\ []) do
    Logger.info("Starting ExESDBGrpc Server with opts: #{inspect(opts)}")
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    port = Keyword.get(opts, :port, 50_051)
    ip = Keyword.get(opts, :ip, {0, 0, 0, 0})

    Logger.info("Initializing gRPC server on port #{port}")

    # Start the gRPC server with direct service configuration
    case GRPC.Server.start([ExESDBGrpc.EventStoreService], port, ip: ip) do
      {:ok, server_pid, actual_port} ->
        Logger.info(
          "gRPC server successfully started on port #{actual_port} with PID: #{inspect(server_pid)}"
        )

        {:ok, %{server_pid: server_pid, port: actual_port, ip: ip}}
      
      {:ok, server_pid} ->
        Logger.info(
          "gRPC server successfully started on port #{port} with PID: #{inspect(server_pid)}"
        )

        {:ok, %{server_pid: server_pid, port: port, ip: ip}}

      {:error, reason} ->
        Logger.error("Failed to start gRPC server: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_call(:info, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info({:EXIT, _pid, reason}, state) do
    Logger.error("gRPC server exited with reason: #{inspect(reason)}")
    {:stop, reason, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("gRPC server terminating: #{inspect(reason)}")

    if Map.has_key?(state, :server_pid) do
      Logger.info("Stopping gRPC server PID: #{inspect(state.server_pid)}")
    end

    :ok
  end
end
