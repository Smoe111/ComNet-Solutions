defmodule ChatEmpresarial.MixProject do
  use Mix.Project

  def project do
    [
      app: :chat_empresarial,
      version: "0.1.0",
      elixir: "~> 1.17.2",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ChatEmpresarial, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
     {:phoenix_pubsub, "~> 2.1"}
    ]
  end
end
