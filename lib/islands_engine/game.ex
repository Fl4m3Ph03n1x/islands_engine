defmodule IslandsEngine.Game  do
  @moduledoc """
  Represents the game entity and feeds the rules state machine with input
  from the user.
  """

  use GenServer

  alias IslandsEngine.{Board, Coordinate, Guesses, Island, Rules}

  @type player_name :: String.t | nil

  @type state ::
    %{
      player1: %{board: map, guesses: %Guesses{}, name: player_name},
      player2: %{board: map, guesses: %Guesses{}, name: player_name},
      rules: %Rules{}
    }

  @players [:player1, :player2]

  # API

  @spec start_link(String.t) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(name) when is_binary(name), do:
    GenServer.start_link(__MODULE__, name, via_tuple(name))

  @spec add_player(pid, String.t) :: :ok
  def add_player(game, name) when is_binary(name), do:
    GenServer.call(game, {:add_player, name})

  @spec position_island(pid, atom, atom, integer, integer) :: any
  def position_island(game, player, key, row, col) when player in @players, do:
    GenServer.call(game, {:position_island, player, key, row, col})

  @spec player_board(state, atom) :: map
  defp player_board(state_data, player), do: Map.get(state_data, player).board

  @spec set_islands(pid, atom) :: map
  def set_islands(game, player) when player in @players, do:
    GenServer.call(game, {:set_islands, player})

  @spec guess_coordinate(pid, atom, integer, integer) :: map
  def guess_coordinate(game, player, row, col) when player in @players, do:
    GenServer.call(game, {:guess_coordinate, player, row, col})

  @spec via_tuple(String.t) :: {:via, Registry, {Registry.Game, String.t}}
  def via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  # callbacks

  @impl GenServer
  @spec init(String.t) :: {:ok, state}
  def init(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}

    {:ok, %{player1: player1, player2: player2, rules: Rules.new()}}
  end

  @impl GenServer
  def handle_call({:add_player, name}, _from, state) do
    with {:ok, new_rules} <- Rules.check(state.rules, :add_player) do
      state_with_p2name = put_in(state.player2.name, name)

      state_with_p2name
      |> update_rules(new_rules)
      |> reply(:ok)
    else
      :error -> {:reply, :error, state}
    end
  end

  @impl GenServer
  def handle_call({:position_island, player, key, row, col}, _from, state) do
    board = player_board(state, player)
    reply_error = create_reply(state)

    with  {:ok, rules}  <- Rules.check(state.rules, {:position_islands, player}),
          {:ok, coord}  <- Coordinate.new(row, col),
          {:ok, island} <- Island.new(key, coord),
          %{} = board   <- Board.position_island(board, key, island)
    do
      state
      |> update_board(player, board)
      |> update_rules(rules)
      |> reply(:ok)
    else
      :error  ->
        reply_error.(:error)
      {:error, :invalid_coordinate}   ->
        reply_error.({:error, :invalid_coordinate})
      {:error, :invalid_island_type}  ->
        reply_error.({:error, :invalid_island_type})
      {:error, :overlapping_island}   ->
        reply_error.({:error, :overlappign_island})
    end
  end

  @impl GenServer
  def handle_call({:set_islands, player}, _from, state) do
    reply_error = create_reply(state)
    board = player_board(state, player)

    with  {:ok, rules}  <- Rules.check(state.rules, {:set_islands, player}),
          true          <- Board.all_islands_positioned?(board)
    do
      state
      |> update_rules(rules)
      |> reply({:ok, board})
    else
      :error  -> reply_error.(:error)
      false   -> reply_error.({:error, :not_all_islands_positioned})
    end
  end

  @impl GenServer
  def handle_call({:guess_coordinate, player, row, col}, _from, state) do
    opponent = opponent(player)
    opponent_board = player_board(state, opponent)
    reply_error = create_reply(state)

    update_guesses = fn(state, player, hit_or_miss, coord) ->
      update_in(state[player].guesses, fn guesses ->
        Guesses.add(guesses, hit_or_miss, coord)
      end)
    end

    with  {:ok, rules}  <-
            Rules.check(state.rules, {:guess_coordinate, player}),
          {:ok, coord}  <-
            Coordinate.new(row, col),
          {hit_or_miss, forested_island, win_status, opponent_board} <-
            Board.guess(opponent_board, coord),
          {:ok, rules}  <-
            Rules.check(rules, {:win_check, win_status})
    do
      state
      |> update_board(opponent, opponent_board)
      |> update_guesses.(player, hit_or_miss, coord)
      |> update_rules(rules)
      |> reply({hit_or_miss, forested_island, win_status})
    else
      :error                        ->
        reply_error.(:error)
      {:error, :invalid_coordinate} ->
        reply_error.({:error, :invalid_coordinate})
    end
  end

  @spec opponent(atom) :: atom
  defp opponent(:player1), do: :player2

  defp opponent(:player2), do: :player1

  @spec reply(state, any):: {:reply, any, state}
  defp reply(state, reply), do: {:reply, reply, state}

  @spec create_reply(state) :: fun
  defp create_reply(state), do: fn error -> reply(state, error) end

  @spec update_board(state, atom, map) :: state
  defp update_board(state, player, board) do
    Map.update!(state, player, fn player -> %{player | board: board} end)
  end

  @spec update_rules(state, %Rules{}) :: state
  defp update_rules(state, rules), do: %{state | rules: rules}

end
