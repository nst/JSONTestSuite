defmodule TestErlangEuneus.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_erlang_euneus,
      version: "0.1.0",
      elixir: "~> 1.16-dev",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: TestErlangEuneus],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:euneus, "~> 0.4.0"}
    ]
  end
end
