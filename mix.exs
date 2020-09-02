defmodule Calc.MixProject do
  use Mix.Project

  def project do
    [
      app: :calc,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: releases()
    ]
  end

  def application do
    [
      mod: {Calc.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.5.4"},
      {:telemetry_metrics, "~> 0.5"},
      {:telemetry_poller, "~> 0.5"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.3"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end

  def releases do
    [
      calc: [
        applications: [runtime_tools: :permanent],
        include_executables_for: [:unix]
      ]
    ]
  end
end
