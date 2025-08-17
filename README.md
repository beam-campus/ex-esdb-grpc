# ExESDBGrpc

[![Hex.pm](https://img.shields.io/hexpm/v/ex_esdb_grpc.svg)](https://hex.pm/packages/ex_esdb_grpc)
[![Documentation](https://img.shields.io/badge/documentation-hexdocs-blue.svg)](https://hexdocs.pm/ex_esdb_grpc)

**gRPC API server for ExESDB event store clusters**

ExESDBGrpc provides an EventStore-compatible gRPC API that allows external clients to read and write events, subscribe to streams, and perform other event store operations over gRPC.

## Features

- 🔌 **EventStore-compatible gRPC API** - Works with existing EventStore clients
- 📖 **Stream operations** - Read and write events to streams
- 📡 **Live subscriptions** - Real-time event streaming with gRPC
- 🏥 **Health checks** - Built-in health monitoring
- 🔄 **Transaction support** - Atomic operations (planned)
- 🛡️ **Stream management** - Create, delete, and manage streams

## Installation

Add `ex_esdb_grpc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_esdb_grpc, "~> 0.1.0"},
    {:ex_esdb_gater, "~> 0.5.0"}  # Required for core functionality
  ]
end
```

## Usage

### Basic Setup

Add the gRPC server to your supervision tree:

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Your other supervisors...
      {ExESDBGrpc.Server, [port: 50_051]}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### Configuration

Configure the gRPC server in your application:

```elixir
config :ex_esdb_grpc,
  enabled: true,
  port: 50051
```

### Available gRPC Services

The package provides the following gRPC services:

#### EventStore Service

- `WriteEvents` - Write events to a stream
- `ReadEvent` - Read a single event
- `ReadStreamEvents` - Read multiple events from a stream
- `ReadAllEvents` - Read from the global event stream
- `SubscribeToStream` - Subscribe to stream events (streaming)
- `DeleteStream` - Delete a stream
- `GetStreamInfo` - Get stream metadata
- `HealthCheck` - Check service health

#### Transaction Support (Planned)

- `StartTransaction` - Begin a transaction
- `WriteToTransaction` - Write events to a transaction
- `CommitTransaction` - Commit a transaction

### Client Examples

Connect from any gRPC client:

```csharp
// C# example
var channel = GrpcChannel.ForAddress("http://localhost:50051");
var client = new EventStore.EventStoreClient(channel);

// Write events
var writeResult = await client.WriteEventsAsync(request);

// Read events
var readResult = await client.ReadStreamEventsAsync(request);

// Subscribe to stream
var subscription = client.SubscribeToStream(request);
while (await subscription.ResponseStream.MoveNext())
{
    var streamEvent = subscription.ResponseStream.Current;
    // Process event...
}
```

```python
# Python example
import grpc
from eventstore_pb2_grpc import EventStoreStub

channel = grpc.insecure_channel('localhost:50051')
client = EventStoreStub(channel)

# Write events
response = client.WriteEvents(write_request)

# Read events
response = client.ReadStreamEvents(read_request)

# Subscribe to stream
for event in client.SubscribeToStream(subscribe_request):
    print(f"Received event: {event}")
```

## Dependencies

This package requires:

- **`ex_esdb_gater`** (~> 0.5.0) - Core event store functionality
- **`grpc`** (~> 0.7) - gRPC server implementation
- **`protobuf`** (~> 0.15) - Protocol buffer support
- **`jason`** (~> 1.0) - JSON encoding/decoding

## Architecture

ExESDBGrpc is part of the ExESDB ecosystem:

- 🏗️ **`ex_esdb_gater`** - Core cluster logic and messaging
- 🎨 **`ex_esdb_dashboard`** - LiveView UI and monitoring
- 🔌 **`ex_esdb_grpc`** - gRPC API server (this package)

## Monitoring

Check if the gRPC server is running:

```elixir
ExESDBGrpc.server_running?()
# => true

ExESDBGrpc.server_info()
# => %{server_pid: #PID<0.123.0>, port: 50051, ip: {0, 0, 0, 0}}
```

## Development

```bash
# Get dependencies
mix deps.get

# Compile
mix compile

# Run tests
mix test

# Generate docs
mix docs
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Links

- [Documentation](https://hexdocs.pm/ex_esdb_grpc)
- [Hex Package](https://hex.pm/packages/ex_esdb_grpc)
- [GitHub](https://github.com/beam-campus/ex-esdb-grpc)
- [ExESDB Core](https://github.com/beam-campus/ex-esdb-gater)
- [ExESDB Dashboard](https://github.com/beam-campus/ex-esdb-dashboard)
