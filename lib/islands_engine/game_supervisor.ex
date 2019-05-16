defmodule IslandsEngine.GameSupervisor do
  use DynamicSupervisor

  alias IslandsEngine.Game

  #######
  # API #
  #######

  @spec start_link(any) :: Supervisor.on_start
  def start_link(_args), do:
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  @spec start_game(String.t) :: DynamicSupervisor.on_start_child
  def start_game(name), do:
    DynamicSupervisor.start_child(__MODULE__, {Game, name})

  @spec stop_game(String.t) :: :ok | {:error, :not_found}
  def stop_game(name) do
    :ets.delete(:game_state, name)
    DynamicSupervisor.terminate_child(__MODULE__, pid_from_name(name))
  end

  #############
  # Callbacks #
  #############

  @impl DynamicSupervisor
  @spec init(:ok) :: {:ok, DynamicSupervisor.sup_flags}
  def init(:ok), do:
    DynamicSupervisor.init(strategy: :one_for_one)

  #################
  # Aux Functions #
  #################

  @spec pid_from_name(String.t) :: pid
  defp pid_from_name(name) do
    name
    |> Game.via_tuple()
    |> GenServer.whereis()
  end

end
