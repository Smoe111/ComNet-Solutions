defmodule ChatEmpresarial.Usuarios do
  use GenServer

  def crear_usuario(nombre) do
    case GenServer.start_link(__MODULE__, nombre, name: String.to_atom(nombre)) do
      {:ok, _pid} ->
        IO.puts("Usuario #{nombre} creado")
        start(nombre)
      {:error, reason} ->
        IO.puts("Error al crear el usuario: #{reason}")
    end
  end

  def lista_usuarios() do
    GenServer.call(ChatEmpresarial.Servidor, :lista_usuarios)
  end

  def init(nombre) do
    {:ok, %{nombre: nombre}}
  end
end
