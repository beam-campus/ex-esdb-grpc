defmodule ExESDBGrpc.EventStoreService do
  @moduledoc """
  gRPC EventStore service implementation for ExESDB.

  This module implements the EventStore gRPC service by delegating to
  the business logic in ExESDBGater.API and other core modules.
  """

  use GRPC.Server, service: Reckondb.Client.Messages.EventStore.Service

  # Since we're creating a standalone gRPC package, we'll need to define our own API
  # that delegates to the appropriate ExESDBGater functions or creates a simple stub
  alias Reckondb.Client.Messages

  require Logger

  @doc """
  Write events to a stream.
  """
  def write_events(request, _stream) do
    Logger.info(
      "gRPC WriteEvents: stream=#{request.event_stream_id}, events=#{length(request.events)}"
    )

    # Convert protobuf events to our internal format
    events = Enum.map(request.events, &convert_new_event/1)
    expected_version = if request.expected_version == -2, do: :any, else: request.expected_version

    # For now, return a stub response - this will need to be connected to actual ExESDBGater API
    case stub_write_events(request.event_stream_id, events, expected_version) do
      {:ok, new_version} ->
        %Messages.WriteEventsCompleted{
          result: :Success,
          message: "",
          first_event_number: new_version - length(events) + 1,
          last_event_number: new_version,
          current_version: new_version,
          # TODO: Get actual positions
          prepare_position: 0,
          commit_position: 0
        }

      {:error, {:wrong_expected_version, current_version}} ->
        %Messages.WriteEventsCompleted{
          result: :WrongExpectedVersion,
          message: "Wrong expected version",
          current_version: current_version,
          first_event_number: -1,
          last_event_number: -1,
          prepare_position: 0,
          commit_position: 0
        }

      {:error, reason} ->
        %Messages.WriteEventsCompleted{
          result: :PrepareTimeout,
          message: "Error: #{inspect(reason)}",
          current_version: -1,
          first_event_number: -1,
          last_event_number: -1,
          prepare_position: 0,
          commit_position: 0
        }
    end
  end

  @doc """
  Read a single event from a stream.
  """
  def read_event(request, _stream) do
    Logger.info(
      "gRPC ReadEvent: stream=#{request.event_stream_id}, event_number=#{request.event_number}"
    )

    case stub_read_stream_events(request.event_stream_id, request.event_number, 1) do
      {:ok, [event]} ->
        %Messages.ReadEventCompleted{
          result: :Success,
          event: convert_to_resolved_indexed_event(event),
          error: ""
        }

      {:ok, []} ->
        %Messages.ReadEventCompleted{
          result: :NotFound,
          event: nil,
          error: "Event not found"
        }

      {:error, :stream_not_found} ->
        %Messages.ReadEventCompleted{
          result: :NoStream,
          event: nil,
          error: "Stream not found"
        }

      {:error, reason} ->
        %Messages.ReadEventCompleted{
          result: :Error,
          event: nil,
          error: "Error: #{inspect(reason)}"
        }
    end
  end

  @doc """
  Read multiple events from a stream.
  """
  def read_stream_events(request, _stream) do
    Logger.info(
      "gRPC ReadStreamEvents: stream=#{request.event_stream_id}, from=#{request.from_event_number}, count=#{request.max_count}"
    )

    case stub_read_stream_events(
           request.event_stream_id,
           request.from_event_number,
           request.max_count
         ) do
      {:ok, events} ->
        converted_events = Enum.map(events, &convert_to_resolved_indexed_event/1)
        next_event_number = request.from_event_number + length(events)

        %Messages.ReadStreamEventsCompleted{
          result: :Success,
          events: converted_events,
          next_event_number: next_event_number,
          last_event_number: next_event_number - 1,
          is_end_of_stream: length(events) < request.max_count,
          # TODO: Get actual position
          last_commit_position: 0,
          error: ""
        }

      {:error, :stream_not_found} ->
        %Messages.ReadStreamEventsCompleted{
          result: :NoStream,
          events: [],
          next_event_number: 0,
          last_event_number: -1,
          is_end_of_stream: true,
          last_commit_position: 0,
          error: "Stream not found"
        }

      {:error, reason} ->
        %Messages.ReadStreamEventsCompleted{
          result: :Error,
          events: [],
          next_event_number: request.from_event_number,
          last_event_number: -1,
          is_end_of_stream: false,
          last_commit_position: 0,
          error: "Error: #{inspect(reason)}"
        }
    end
  end

  @doc """
  Read all events from the global stream.
  """
  def read_all_events(request, _stream) do
    Logger.info(
      "gRPC ReadAllEvents: commit_pos=#{request.commit_position}, count=#{request.max_count}"
    )

    # For now, we'll implement this as a simple operation
    # In a real implementation, this would read from a global log
    %Messages.ReadAllEventsCompleted{
      result: :Success,
      commit_position: request.commit_position,
      prepare_position: request.prepare_position,
      events: [],
      next_commit_position: request.commit_position,
      next_prepare_position: request.prepare_position,
      error: ""
    }
  end

  @doc """
  Subscribe to events from a stream (streaming RPC).
  """
  def subscribe_to_stream(request, stream) do
    Logger.info("gRPC SubscribeToStream: stream=#{request.event_stream_id}")

    # Start a live subscription using our API
    case stub_subscribe_to_stream(request.event_stream_id, self()) do
      {:ok, subscription_pid} ->
        Logger.info("Started subscription for gRPC stream: #{request.event_stream_id}")

        # Send initial confirmation
        send_subscription_confirmation(stream, request.event_stream_id)

        # Start receiving events and forward them to the gRPC stream
        handle_subscription_events(stream, request.event_stream_id, subscription_pid)

      {:error, reason} ->
        Logger.error("Failed to start subscription: #{inspect(reason)}")
        # Send an error event and close
        send_subscription_error(stream, request.event_stream_id, reason)
    end
  end

  @doc """
  Delete a stream.
  """
  def delete_stream(request, _stream) do
    Logger.info("gRPC DeleteStream: stream=#{request.event_stream_id}")

    case stub_delete_stream(request.event_stream_id) do
      :ok ->
        %Messages.DeleteStreamCompleted{
          result: :Success,
          message: "Stream deleted",
          prepare_position: 0,
          commit_position: 0,
          current_version: -1
        }

      {:error, reason} ->
        %Messages.DeleteStreamCompleted{
          result: :PrepareTimeout,
          message: "Error: #{inspect(reason)}",
          prepare_position: 0,
          commit_position: 0,
          current_version: -1
        }
    end
  end

  @doc """
  Start a transaction.
  """
  def start_transaction(request, _stream) do
    Logger.info("gRPC StartTransaction: stream=#{request.event_stream_id}")

    # For now, return a simple transaction ID
    # TODO: Implement actual transaction support
    %Messages.TransactionStartCompleted{
      transaction_id: :rand.uniform(1_000_000),
      result: :Success,
      message: "Transaction started"
    }
  end

  @doc """
  Write to a transaction.
  """
  def write_to_transaction(request, _stream) do
    Logger.info("gRPC WriteToTransaction: transaction_id=#{request.transaction_id}")

    %Messages.TransactionWriteCompleted{
      transaction_id: request.transaction_id,
      result: :Success,
      message: "Events written to transaction"
    }
  end

  @doc """
  Commit a transaction.
  """
  def commit_transaction(request, _stream) do
    Logger.info("gRPC CommitTransaction: transaction_id=#{request.transaction_id}")

    %Messages.TransactionCommitCompleted{
      transaction_id: request.transaction_id,
      result: :Success,
      message: "Transaction committed",
      first_event_number: 0,
      last_event_number: 0,
      prepare_position: 0,
      commit_position: 0
    }
  end

  @doc """
  Health check.
  """
  def health_check(request, _stream) do
    Logger.info("gRPC HealthCheck: service=#{request.service}")

    case stub_health_check() do
      :ok ->
        %Messages.HealthCheckResponse{
          status: :SERVING
        }

      {:error, _reason} ->
        %Messages.HealthCheckResponse{
          status: :NOT_SERVING
        }
    end
  end

  @doc """
  Get stream information.
  """
  def get_stream_info(request, _stream) do
    Logger.info("gRPC GetStreamInfo: stream=#{request.event_stream_id}")

    case stub_get_stream_info(request.event_stream_id) do
      {:ok, info} ->
        %Messages.GetStreamInfoResponse{
          event_stream_id: info.stream_id,
          current_version: info.current_version,
          event_count: info.event_count,
          exists: info.exists,
          created_date: info.created_date || 0
        }

      {:error, _reason} ->
        %Messages.GetStreamInfoResponse{
          event_stream_id: request.event_stream_id,
          current_version: -1,
          event_count: 0,
          exists: false,
          created_date: 0
        }
    end
  end

  # Private helper functions

  defp convert_new_event(proto_event) do
    %{
      type: proto_event.event_type,
      data: Jason.decode!(proto_event.data),
      metadata:
        if(proto_event.metadata == "", do: %{}, else: Jason.decode!(proto_event.metadata)),
      id: Base.encode16(proto_event.event_id, case: :lower)
    }
  rescue
    _ ->
      %{
        type: proto_event.event_type,
        data: %{raw: proto_event.data},
        metadata: %{},
        id: Base.encode16(proto_event.event_id, case: :lower)
      }
  end

  defp convert_to_resolved_indexed_event(event) do
    %Messages.ResolvedIndexedEvent{
      event: %Messages.EventRecord{
        event_stream_id: Map.get(event, :stream_id, ""),
        event_number: Map.get(event, :event_number, 0),
        event_id: Map.get(event, :event_id, ""),
        event_type: Map.get(event, :event_type, ""),
        # JSON
        data_content_type: 1,
        # JSON
        metadata_content_type: 1,
        data: Jason.encode!(Map.get(event, :data, %{})),
        metadata: Jason.encode!(Map.get(event, :metadata, %{})),
        created: Map.get(event, :created, System.system_time(:millisecond)),
        created_epoch: Map.get(event, :created_epoch, System.system_time(:second)),
        properties: ""
      },
      # No link event for now
      link: nil
    }
  end

  # Subscription helper functions

  defp send_subscription_confirmation(stream, stream_id) do
    confirmation_event = %Messages.StreamEventAppeared{
      event: %Messages.ResolvedEvent{
        event: %Messages.EventRecord{
          event_stream_id: stream_id,
          event_number: -1,
          event_id: "subscription_confirmed",
          event_type: "SubscriptionConfirmed",
          data_content_type: 1,
          metadata_content_type: 1,
          data: Jason.encode!(%{message: "Subscription confirmed", stream: stream_id}),
          metadata: "{}",
          created: System.system_time(:millisecond),
          created_epoch: System.system_time(:second),
          properties: ""
        },
        link: nil,
        commit_position: 0,
        prepare_position: 0
      }
    }

    GRPC.Server.send_reply(stream, confirmation_event)
  end

  defp send_subscription_error(stream, stream_id, reason) do
    error_event = %Messages.StreamEventAppeared{
      event: %Messages.ResolvedEvent{
        event: %Messages.EventRecord{
          event_stream_id: stream_id,
          event_number: -1,
          event_id: "subscription_error",
          event_type: "SubscriptionError",
          data_content_type: 1,
          metadata_content_type: 1,
          data: Jason.encode!(%{error: inspect(reason), stream: stream_id}),
          metadata: "{}",
          created: System.system_time(:millisecond),
          created_epoch: System.system_time(:second),
          properties: ""
        },
        link: nil,
        commit_position: 0,
        prepare_position: 0
      }
    }

    GRPC.Server.send_reply(stream, error_event)
  end

  defp handle_subscription_events(stream, stream_id, subscription_pid) do
    receive do
      {:stream_events, ^stream_id, events} ->
        # Forward each event to the gRPC stream
        Enum.each(events, fn event ->
          stream_event = %Messages.StreamEventAppeared{
            event: convert_to_resolved_event(event)
          }

          GRPC.Server.send_reply(stream, stream_event)
        end)

        # Continue listening for more events
        handle_subscription_events(stream, stream_id, subscription_pid)
    after
      # 30 second timeout
      30_000 ->
        Logger.info("Subscription timeout for stream: #{stream_id}")
        stub_unsubscribe_from_stream(subscription_pid)
    end
  end

  defp convert_to_resolved_event(event) do
    %Messages.ResolvedEvent{
      event: %Messages.EventRecord{
        event_stream_id: Map.get(event, :stream_id, ""),
        event_number: Map.get(event, :event_number, 0),
        event_id: Map.get(event, :event_id, ""),
        event_type: Map.get(event, :event_type, ""),
        # JSON
        data_content_type: 1,
        # JSON
        metadata_content_type: 1,
        data: Jason.encode!(Map.get(event, :data, %{})),
        metadata: Jason.encode!(Map.get(event, :metadata, %{})),
        created: Map.get(event, :created, System.system_time(:millisecond)),
        created_epoch: Map.get(event, :created_epoch, System.system_time(:second)),
        properties: ""
      },
      link: nil,
      commit_position: Map.get(event, :commit_position, 0),
      prepare_position: Map.get(event, :prepare_position, 0)
    }
  end

  # Stub API functions - These should be replaced with actual ExESDBGater API calls
  # when integrating with a real ExESDB cluster

  defp stub_write_events(_stream_id, events, _expected_version) do
    # Simulate successful write
    {:ok, length(events)}
  end

  defp stub_read_stream_events(_stream_id, _start_version, _count) do
    # Return empty events for now
    {:ok, []}
  end

  defp stub_subscribe_to_stream(_stream_id, _subscriber_pid) do
    # Simulate subscription creation
    {:ok, spawn(fn -> :ok end)}
  end

  defp stub_delete_stream(_stream_id) do
    :ok
  end

  defp stub_health_check do
    :ok
  end

  defp stub_get_stream_info(stream_id) do
    {:ok,
     %{
       stream_id: stream_id,
       current_version: 0,
       event_count: 0,
       exists: false,
       created_date: nil
     }}
  end

  defp stub_unsubscribe_from_stream(_subscription_pid) do
    :ok
  end
end
