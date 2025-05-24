defmodule Proyecto.Servidor do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{
      usuarios: %{}, # %{nombre => %{pid, sala}}
      salas: %{"general" => []}, # %{sala => [usuarios]}
      mensajes: %{"general" => []} # %{sala => [mensajes]}
    }, name: {:global, __MODULE__})
  end
end
