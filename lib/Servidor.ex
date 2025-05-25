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
  #Crear sala
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
  #Abandonar sala (Opcional)
  def handle_call({:abandonar_sala, nombre}, _from, state) do
    sala = state.usuarios[nombre][:sala]
    salas = update_in(state.salas[sala], fn lista -> List.delete(List.wrap(lista), nombre) end)
    usuarios = Map.update!(state.usuarios, nombre, &Map.put(&1, :sala, nil))
    {:reply, :ok, %{state | salas: salas, usuarios: usuarios}}
  end
  #Listar usuarios
  def handle_call(:listar_usuarios, _from, state) do
    {:reply, {:ok, Map.keys(state.usuarios)}, state}
  end
  #Historial mensajes
  def handle_call({:listar_historial, sala}, _from, state) do
    {:reply, {:ok, Map.get(state.mensajes, sala, [])}, state}
  end
  #Sala actual
  def handle_call({:obtener_sala_actual, nombre}, _from, state) do
    case Map.get(state.usuarios, nombre) do
      nil -> {:reply, {:error, "Usuario no conectado"}, state}
      usuario -> {:reply, {:ok, usuario[:sala]}, state}
    end
  end
  #Enviar mensaje
  def handle_cast({:enviar_mensaje, usuario, sala, mensaje}, state) do
    {{año, mes, dia}, {hora, minutos, segundos}} = :calendar.local_time()
    timestamp = :io_lib.format("~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B", [año, mes, dia, hora, minutos, segundos]) |> IO.iodata_to_binary()
    mensaje_formateado = "[#{timestamp}] [#{sala}] #{usuario}: #{mensaje}"
    mensajes = Map.update(state.mensajes, sala, [mensaje_formateado], fn mensaje -> [mensaje_formateado | mensaje] end)
    usuarios_sala = Map.get(state.salas, sala, [])
    Enum.each(usuarios_sala, fn nombre ->
      if Map.has_key?(state.usuarios, nombre) do
        send(state.usuarios[nombre].pid, {:mensaje, mensaje_formateado})
      end
    end)
    guardar_mensajes(sala, mensaje_formateado)
    {:noreply, %{state | mensajes: mensajes}}
  end
  #Guardar mensajes en un archivo CSV
  defp guardar_mensajes(sala, mensaje) do
    File.write("mensajes_#{sala}.csv", mensaje <> "\n", [:append])
  end
end
