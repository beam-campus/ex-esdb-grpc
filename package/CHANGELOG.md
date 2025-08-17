# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-08-15

### Added
- Initial release of `ex_esdb_grpc` as a separate gRPC API package
- EventStore-compatible gRPC API server
- `ExESDBGrpc.Server` - gRPC server GenServer with lifecycle management
- `ExESDBGrpc.Endpoint` - gRPC endpoint for service registration
- `ExESDBGrpc.EventStoreService` - Complete EventStore gRPC service implementation
- `ExESDBGrpc.Application` - Application supervisor with configurable startup
- Protocol buffer definitions for EventStore API compatibility
- Real-time event streaming with `SubscribeToStream` RPC
- Stream operations: read, write, delete, and metadata retrieval
- Health check endpoint for service monitoring
- Transaction support framework (basic implementation)

### Features
- **EventStore Compatibility**: Works with existing EventStore gRPC clients
- **Stream Operations**: Complete CRUD operations for event streams
- **Live Subscriptions**: Real-time event streaming via gRPC
- **Health Monitoring**: Built-in health check service
- **Configurable Server**: Port and IP configuration support
- **Error Handling**: Comprehensive error responses and logging
- **JSON Serialization**: Automatic JSON encoding/decoding for event data
- **Subscription Management**: Automatic cleanup and timeout handling

### gRPC Services
#### EventStore Service
- `WriteEvents` - Write events to a stream with optimistic concurrency
- `ReadEvent` - Read a single event by stream and event number
- `ReadStreamEvents` - Read multiple events from a stream with pagination
- `ReadAllEvents` - Read from the global event stream (placeholder)
- `SubscribeToStream` - Subscribe to stream events with real-time updates
- `DeleteStream` - Delete a stream (soft delete)
- `GetStreamInfo` - Retrieve stream metadata and statistics
- `HealthCheck` - Service health monitoring

#### Transaction Support (Basic)
- `StartTransaction` - Begin a new transaction
- `WriteToTransaction` - Write events to an open transaction
- `CommitTransaction` - Commit a transaction atomically

### Dependencies
- ExESDBGater (~> 0.5.0) for core event store functionality
- gRPC (~> 0.7) for gRPC server implementation
- Protobuf (~> 0.15) for protocol buffer support
- Jason (~> 1.0) for JSON encoding/decoding

### Technical Notes
- Extracted from `reckon_admin` system as a standalone package
- Clean integration with ExESDBGater API layer
- Supports both secure and development modes
- Automatic subscription cleanup and resource management
- Compatible with EventStore client libraries

### Configuration Options
```elixir
config :ex_esdb_grpc,
  enabled: true,        # Enable/disable gRPC server
  port: 50051          # gRPC server port
```

### Usage Examples
```elixir
# Add to supervision tree
{ExESDBGrpc.Server, [port: 50051]}

# Check server status
ExESDBGrpc.server_running?()
ExESDBGrpc.server_info()
```

[Unreleased]: https://github.com/beam-campus/ex-esdb-grpc/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/beam-campus/ex-esdb-grpc/releases/tag/v0.1.0
