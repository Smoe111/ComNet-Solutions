defmodule ChatEmpresarial do

  @moduledoc """
  Este es el módulo principal del programa de chat empresarial. Aquí se definen las funciones
  """

  use Application

  def start(_type, _args) do
    # Inicia el supervisor y los procesos necesarios para el chat empresarial
    children =
      if Node.self() == :"servidor@192.168.1.1" do #busca el nodo servidor
        # Si el nodo actual es el servidor, inicia el servidor
        [
          {Registry, keys: :unique, name: ChatEmpresarial.Registry},
          ChatEmpresarial.Servidor,
        ]
      else # sino creao un servidor estandar de elixir
        [
          {Registry, keys: :unique, name: ChatEmpresarial.Registry},
        ]
      end

    opts = [strategy: :one_for_one, name: ChatEmpresarial.Supervisor]
    Supervisor.start_link(children, opts)  #modulo de elixir, inicia el servidor

  end
end
