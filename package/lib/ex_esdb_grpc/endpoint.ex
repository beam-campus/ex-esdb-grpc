defmodule ExESDBGrpc.Endpoint do
  @moduledoc """
  gRPC Endpoint for ExESDB EventStore services.

  This endpoint serves the gRPC API and registers all available gRPC services.
  """

  use GRPC.Endpoint
  require Logger

  # Register our gRPC services with proper service specification
  run ExESDBGrpc.EventStoreService
end
