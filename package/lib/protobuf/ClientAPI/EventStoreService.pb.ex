defmodule Reckondb.Client.Messages.HealthCheckResponse.ServingStatus do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field :UNKNOWN, 0
  field :SERVING, 1
  field :NOT_SERVING, 2
end

defmodule Reckondb.Client.Messages.HealthCheckRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field :service, 1, type: :string
end

defmodule Reckondb.Client.Messages.HealthCheckResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field :status, 1, type: Reckondb.Client.Messages.HealthCheckResponse.ServingStatus, enum: true
end

defmodule Reckondb.Client.Messages.GetStreamInfoRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field :event_stream_id, 1, type: :string, json_name: "eventStreamId"
end

defmodule Reckondb.Client.Messages.GetStreamInfoResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field :event_stream_id, 1, type: :string, json_name: "eventStreamId"
  field :current_version, 2, type: :int64, json_name: "currentVersion"
  field :event_count, 3, type: :int64, json_name: "eventCount"
  field :exists, 4, type: :bool
  field :created_date, 5, type: :int64, json_name: "createdDate"
end

defmodule Reckondb.Client.Messages.ListStoresRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3
end

defmodule Reckondb.Client.Messages.ListStoresResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field :stores, 1, repeated: true, type: Reckondb.Client.Messages.StoreInfo
end

defmodule Reckondb.Client.Messages.StoreInfo do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field :store_id, 1, type: :string, json_name: "storeId"
  field :name, 2, type: :string
  field :active, 3, type: :bool
  field :event_count, 4, type: :int64, json_name: "eventCount"
  field :stream_count, 5, type: :int64, json_name: "streamCount"
end

defmodule Reckondb.Client.Messages.EventStore.Service do
  @moduledoc false

  use GRPC.Service,
    name: "reckondb.client.messages.EventStore",
    protoc_gen_elixir_version: "0.14.1"

  rpc :WriteEvents,
      Reckondb.Client.Messages.WriteEvents,
      Reckondb.Client.Messages.WriteEventsCompleted

  rpc :ReadEvent, Reckondb.Client.Messages.ReadEvent, Reckondb.Client.Messages.ReadEventCompleted

  rpc :ReadStreamEvents,
      Reckondb.Client.Messages.ReadStreamEvents,
      Reckondb.Client.Messages.ReadStreamEventsCompleted

  rpc :ReadAllEvents,
      Reckondb.Client.Messages.ReadAllEvents,
      Reckondb.Client.Messages.ReadAllEventsCompleted

  rpc :SubscribeToStream,
      Reckondb.Client.Messages.SubscribeToStream,
      stream(Reckondb.Client.Messages.StreamEventAppeared)

  rpc :DeleteStream,
      Reckondb.Client.Messages.DeleteStream,
      Reckondb.Client.Messages.DeleteStreamCompleted

  rpc :StartTransaction,
      Reckondb.Client.Messages.TransactionStart,
      Reckondb.Client.Messages.TransactionStartCompleted

  rpc :WriteToTransaction,
      Reckondb.Client.Messages.TransactionWrite,
      Reckondb.Client.Messages.TransactionWriteCompleted

  rpc :CommitTransaction,
      Reckondb.Client.Messages.TransactionCommit,
      Reckondb.Client.Messages.TransactionCommitCompleted

  rpc :HealthCheck,
      Reckondb.Client.Messages.HealthCheckRequest,
      Reckondb.Client.Messages.HealthCheckResponse

  rpc :GetStreamInfo,
      Reckondb.Client.Messages.GetStreamInfoRequest,
      Reckondb.Client.Messages.GetStreamInfoResponse
end

defmodule Reckondb.Client.Messages.EventStore.Stub do
  @moduledoc false

  use GRPC.Stub, service: Reckondb.Client.Messages.EventStore.Service
end

defmodule Reckondb.Client.Messages.StoreManagement.Service do
  @moduledoc false

  use GRPC.Service,
    name: "reckondb.client.messages.StoreManagement",
    protoc_gen_elixir_version: "0.14.1"

  rpc :ListStores,
      Reckondb.Client.Messages.ListStoresRequest,
      Reckondb.Client.Messages.ListStoresResponse
end

defmodule Reckondb.Client.Messages.StoreManagement.Stub do
  @moduledoc false

  use GRPC.Stub, service: Reckondb.Client.Messages.StoreManagement.Service
end
