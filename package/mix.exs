defmodule ExESDBGrpc.MixProject do
  @moduledoc false
  use Mix.Project

  @version "0.4.0"
  @source_url "https://github.com/beam-campus/ex-esdb-grpc"

  def project do
    [
      app: :ex_esdb_grpc,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "ExESDBGrpc",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ExESDBGrpc.Application, []}
    ]
  end

  defp deps do
    [
      {:ex_esdb_gater, "~> 0.7"},
      {:grpc, "~> 0.7"},
      {:protobuf, "~> 0.15"},
      {:jason, "~> 1.0"},

      # Dev/test dependencies
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    gRPC API server for ExESDB event store clusters.
    Provides EventStore-compatible gRPC API for reading and writing events.
    """
  end

  defp package do
    [
      files: ~w(lib priv mix.exs README.md CHANGELOG.md),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      maintainers: ["Beam Campus"]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
