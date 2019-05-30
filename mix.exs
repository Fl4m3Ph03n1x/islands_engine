defmodule IslandsEngine.MixProject do
  use Mix.Project

  def project do
    [
      app: :islands_engine,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {IslandsEngine.Application, []}
    ]
  end

  defp deps do
    [
      {:dialyxir,     "~> 0.5",   only: [:dev],         runtime: false  },
      {:credo,        "~> 1.0.0", only: [:dev, :test],  runtime: false  }
    ]
  end
end
