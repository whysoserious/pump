defmodule Pump.MixProject do
  use Mix.Project

  def project do
    [
      app: :pump,
      version: "1.0.1",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Pump.Application, []},
      extra_applications: [:logger, :os_mon]
    ]
  end

  defp deps do
    [{:jason, "~> 1.0"}, {:tesla, "1.0.0-beta.1"}]
  end
end
