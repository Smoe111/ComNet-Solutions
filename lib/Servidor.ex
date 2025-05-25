defmodule Proyecto.Servidor do
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

  def handle_call({:crear_sala, nombre_sala}, _from, state) do
    if Map.has_key?(state.salas, nombre_sala) do
      {:reply, {:error, "La sala ya existe"}, state}
    else
      salas = Map.put(state.salas, nombre_sala, [])
      mensajes = Map.put(state.mensajes, nombre_sala, [])
      {:reply, :ok, %{state | salas: salas, mensajes: mensajes}}
    end
  end

  def handle_call({:unirse_sala, nombre,nombre_sala}, _from, state) do
    if Map.has_key?(state.salas, nombre_sala) do
      {:reply, {:error, "La sala no existe"}, state}
    else
      sala_anterior = state.usuarios[nombre][:sala]
      salas =
        state.salas
        |> Map.update!(sala_anterior, fn lista -> List.delete(lista, nombre) end)
        |> Map.update!(nombre_sala, fn lista -> [nombre | lista] end)
      usuarios = Map.update!(state.usuarios, nombre, &Map.put(&1, :sala, nombre_sala))
      {:reply, :ok, %{state | salas: salas, usuarios: usuarios}}
    end
  end

end
