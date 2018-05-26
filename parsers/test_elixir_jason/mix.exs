defmodule TestElixirJason.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_elixir_jason,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: TestElixirJason],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [{:jason, "~> 1.0"}]
  end
end
