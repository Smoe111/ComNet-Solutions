defmodule ChatEmpresarial.Salas do

  use GenServer

  @moduledoc """
  Este módulo gestiona las salas de chat y los comandos asociados a ellas. Funciona como una ramificacion del servidor
  y permite crear, eliminar y gestionar salas de chat. Cada sala tiene su propio historial de mensajes y usuarios conectados.
  """
  defstruct [usuarios: [], mensajes: []]

  def start_link(nombre) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: {:global, via_tupla(nombre)})
  end

  def via_tupla(nombre) do
    {:via, Registry, {ChatEmpresarial.Registry, nombre}}
    end

    @impl true
    def init(state) do
      {:ok, state}
  end

  def agregar_usuario(sala, usuario) do
    GenServer.call(via_tupla(sala), {:agregar_usuario, usuario})
  end

  def eliminar_usuario(sala, usuario) do
    GenServer.call(via_tupla(sala), {:eliminar_usuario, usuario})
  end

  def enviar_mensaje(sala, usuario, mensaje) do
    GenServer.call(via_tupla(sala), {:enviar_mensaje, usuario, mensaje})
  end

  def listar_mensajes(sala) do
    GenServer.call(via_tupla(sala), :listar_mensajes)
  end

  # Ramificacion del servidor para la persistencia de mensajes y registro de usuarios

  @impl true
  def handle_call({:agregar_usuario, usuario}, _from, state) do
    if usuario do
    {:reply, {:error,"El usuario ya esta en la sala"}, state}
    else
      {:reply, :ok, %{state | usuarios: [usuario | state.usuarios]}}
    end
  end

  @impl true
  def handle_call({:eliminar_usuario, usuario}, _from, state) do
    if usuario in state.usuarios do
      {:reply, :ok, %{state | usuarios: List.delete(state.usuarios, usuario)}}
    else
      {:reply, {:error,"El usuario no esta en la sala"}, state}
    end
  end

  @impl true
  def handle_call({:enviar_mensaje, usuario, mensaje}, _from, state) do
    if usuario in state.usuarios do
      mensaje = %{usuario: usuario, mensaje: mensaje, timestamp: DateTime.utc_now()}
      {:reply, :ok, %{state | mensajes: [mensaje | state.mensajes]}}
    else
      {:reply, {:error,"El usuario no esta en la sala"}, state}
    end
  end

  @impl true
  def handle_call(:listar_mensajes, _from, state) do
    {:reply, {:ok, Enum.reverse(state.mensajes)}, state}
  end

  def handle_call(:listar_usuarios, _from, state) do
    {:reply, {:ok, state.usuarios}, state}
  end

end
