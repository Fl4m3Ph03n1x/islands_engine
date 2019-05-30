defmodule IslandsEngine.Application do
  @moduledoc false

  use Application

  @spec start(any, any) ::
    {:ok, pid} | {:error, {:already_started, pid} | {:shutdown, atom} | atom}
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Registry.Game},
      IslandsEngine.GameSupervisor
    ]

    :ets.new(:game_state, [:public, :named_table])
    opts = [strategy: :one_for_one, name: IslandsEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
