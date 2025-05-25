defmodule ChatEmpresarial.MixProject do

  use Mix.Project

    def project do
    [
      app: :chat_empresarial,
      version: "0.1.0",
      elixir: "~> 1.18.2",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
    end

    def application do
      [
        mod: {ChatEmpresarial, []},
        extra_applications: [:logger]
      ]
    end

    defp deps do
      [
        {:phoenix_pubsub, "~> 2.1"}
      ]
    end

end
