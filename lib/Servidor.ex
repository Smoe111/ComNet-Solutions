defmodule ChatEmpresarial.Servidor do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{
      usuarios: %{}, # %{nombre => %{pid, sala}}
      salas: %{"general" => []}, # %{sala => [usuarios]}
      mensajes: %{"general" => []} # %{sala => [mensajes]}
    }, name: {:global, __MODULE__})
  end

  def init(state), do: {:ok,state}

  #Conectar un usuario
  def handle_call({:connect, nombre, pid}, _from, state) do
    if Map.has_key?(state.usuarios, nombre) do
      {:reply, {:error, "Usuario ya conectado"}, state}
    else
      usuarios = Map.put(state.usuarios, nombre, %{pid: pid, sala: "general"})
      salas = Map.update!(state.salas, "general", fn usuarios -> [nombre | usuarios] end)
      {:reply, :ok, %{state | usuarios: usuarios, salas: salas}}
    end
  end


end
