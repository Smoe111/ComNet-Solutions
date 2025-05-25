defmodule ChatEmpresarial.Usuarios do

    @moduledoc """
  Este módulo gestiona los usuarios conectados al programa y quienes se encuentran activos
  """

  defstruct [:nombre, :pid]

  def usuario(nombre) do

    case GenServer.start_link(__MODULE__, nombre, name: String.to_atom(nombre)) do #corregir que encuentre el servidor como sea
       {:ok, _pid}->
        IO.puts("Usuario #{nombre} conectado.")
        start(nombre)

        {:error, mensaje} ->
          IO.puts("Error al crear el usuario: #{mensaje}")
    end
  end

  def start(nombre) do
    case GenServer.call({:global, ChatEmpresarial.Servidor}, {:connect, nombre, self()}) do
      :ok ->
        IO.puts("Bienvenido al chat, #{nombre}!")
        comandos(nombre)

      {:error, mensaje} ->
        IO.puts("Error al conectar el usuario: #{mensaje}")
    end
  end

  def init (nombre) do
    {:ok, %{nombre: nombre}}
  end

  def lista_usuarios() do

    GenServer.call(ChatEmpresarial.Servidor, :lista_usuarios)
  end

  defp comandos(nombre) do

    IO.puts("""

    Bienvenido al chat empresarial, #{nombre}!

    Comandos disponibles:
    - /list  = Ver usuarios conectados
    - /join [sala]  = Unirse a una sala
    - /create [sala] = Crear una sala
    - /historial [sala] = Ver el historial de la sala
    - /leave  = abandonar la sala actual
    - /exit = Salir del chat

    """)
    spawn(fn-> loop(nombre)end)
    listen(nombre)

  end

  defp listen(nombre) do

    receive do
      {:mensaje, mensaje} -> IO.puts("Nuevo mensaje: #{mensaje}") #espera un mensaje del servidor
      listen(nombre)
    end
  end

  def loop(nombre) do

    comando= IO.gets(">") |> String.trim()
    case procesar_comando(nombre, comando) do
      :exit -> :ok
      _-> loop(nombre)
    end
  end

  defp procesar_comando(nombre, comando) do

    cond do
      comando == "/list" ->
        case GenServer.call({:global, ChatEmpresarial.Servidor}, :listar_usuarios) do
          {:ok, usuarios}->
            IO.puts("Usuarios conectados:")
            Enum.each(usuarios, &IO.puts(" - #{&1}"))
          {:error, mensaje} ->
            IO.puts("Error al listar usuarios: #{mensaje}")
        end

      String.starts_with?(comando, "/join") -> # verifica si el comando empieza con /join
        sala= String.replace_prefix(comando, "/join ", "")  # reemplaza un prefijo por un vacio para obtener el nombre de la sala
        case GenServer.call({:global, ChatEmpresarial.Servidor}, {:entrar_sala, nombre, sala}) do
          :ok ->
            IO.puts("Te has unido a la sala #{sala}")
          {:error, mensaje} ->
            IO.puts("Error al unirse a la sala: #{mensaje}")
        end

      String.starts_with?(comando, "/create") ->
        sala= String.replace_prefix(comando, "/create ", "")
        case GenServer.call({:global, ChatEmpresarial.Servidor}, {:crear_sala, sala}) do
          :ok ->
            IO.puts("Se ha creado la sala #{sala}")
          {:error, mensaje} ->
            IO.puts("Error al crear la sala: #{mensaje}")
        end
      String.starts_with?(comando, "/history") ->
        [_, sala | _ ]= String.split(comando, " ", parts: 3)
        case GenServer.call({:global, ChatEmpresarial.Servidor}, {:listar_historial, sala}) do
          {:ok, historial} ->
            IO.puts("Historial de la sala #{sala}:")
            Enum.each(Enum.reverse(historial), &IO.puts(&1)) # imprime el historial en orden cronológico
          {:error, mensaje} ->
            IO.puts("Error al obtener el historial: #{mensaje}")
        end
      comando == "/leave"->
        case GenServer.call({:global, ChatEmpresarial.Servidor}, {:abandonar_sala, nombre}) do
          :ok ->
            IO.puts("Has salido de la sala")
          {:error, mensaje} ->
            IO.puts("Error al salir de la sala: #{mensaje}")
        end
      comando == "/exit" ->
        IO.puts("Saliendo del chat...")
        :exit

      String.starts_with?(comando, "/") ->
        IO.puts("Comando inválido. Usa /list, /join [sala], /create [sala], /historial [sala], /leave ó /exit.")
        :ok

      true ->
        #si no es un comando se interpreta como un mensaje o consultar la sala actual
        case GenServer.call({:global, ChatEmpresarial.Servidor}, {:obtener_sala_actual, nombre}) do
          {:ok, nil} ->
            IO.puts("No estás en ninguna sala. Puedes unirte a una sala usando /join [sala].")
          {:ok, sala_actual} ->
            GenServer.cast({:global, ChatEmpresarial.Servidor}, {:enviar_mensaje, nombre, sala_actual, comando})
          {:error, mensaje} ->
            IO.puts("Error al obtener sala actual: #{mensaje}")
        end
        :ok
    end
  end
end
