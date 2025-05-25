defmodule ChatEmpresarial.Usuarios do

    @moduledoc """
  Este módulo gestiona los usuarios conectados al programa y quienes se encuentran activos
  """

  defstruct [:nombre, :pid]

  def usuario(nombre) do

    case GenServer.start_link(_MODULE_, nombre, name: String.to_atom(nombre)) do #corregir que encuentre el servidor como sea
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
    - /list  = Ver usuarios conectados"
    - /join [sala]  = Unirse a una sala"
    - /create [sala] = Crear una sala"
    - /send [mensaje] [sala]= Enviar un mensaje a la sala"
    - /historial [sala] = Ver el historial de la sala"
    - /exit = Salir del chat"

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

  defp procesar_comando("/list", nombre) do

    usuarios= ChatEmpresarial.Usuarios.lista_usuarios()
    IO.puts("Usuarios conectados:")
    Enum.each(usuarios, fn usuario ->
      IO.puts(" - #{usuario.nombre}")
    end)
    listen(cliente)

  end

  defp procesar_comando("/join" <> sala, %ChatEmpresarial.Usuarios{}= cliente ) do

    join_sala(cliente.nombre, sala)
    IO.puts("Te has unido a la sala #{sala}")
    listen(cliente)
  end

  defp procesar_comando("/create" <> sala, %ChatEmpresarial.Usuarios{}= cliente) do

    create_sala(sala)
    IO.puts("Se ha creado la sala #{sala}")
    listen(cliente)
  end

  defp procesar_comando("/send" <> rest, %ChatEmpresarial.Usuarios{}= cliente) do

    case String.split(rest, "", parts: 2) do
      [mensaje, sala] ->
        send_mensaje(mensaje, sala, cliente.nombre)
        IO.puts("Mensaje enviado a la sala #{sala}: #{mensaje}")
        listen(cliente)

      _ ->
        IO.puts("Comando inválido. Usa /send [mensaje] [sala]")
        listen(cliente)
    end
  end

  defp procesar_comando("/historial" <> sala, %ChatEmpresarial.Usuarios{}= cliente) do

    case ChatEmpresarial.Historial.leer_historial(sala) do
      mensajes when is_list(mensajes) ->
        IO.puts("Historial de la sala #{sala}:")
        Enum.each(mensajes, fn {hora, usuario, mensaje} -> IO.puts( "[ #{hora} ] - #{usuario}: #{mensaje}") end)
    otro->
      IO.puts("#{otro}") # cualquier error o string que no sea una lista
    end
    listen(cliente)

  end

  defp procesar_comando("/exit", %ChatEmpresarial.Usuarios{}= cliente) do

    GenServer.cast(ChatEmpresarial.Servidor, {:disconnect, cliente.nombre})
    IO.puts("Te has desconectado del chat.")
    :ok
  end

  defp procesar_comando(_comando, %ChatEmpresarial.Usuarios{}= cliente) do

    IO.puts("Comando inválido. Usa /list, /join [sala], /create [sala], /send [mensaje] [sala] o /exit.")
    listen(cliente)
  end

  def create_sala(sala) do

    GenServer.cast(ChatEmpresarial.Servidor, {:create, sala})
  end

  def join_sala(usuario, sala) do
    GenServer.cast(ChatEmpresarial.Servidor, {:join, usuario, sala})
  end

  def send_mensaje(mensaje, sala, usuario) do

    GenServer.cast(ChatEmpresarial.Servidor, {:send, mensaje, sala, usuario})
  end

end
