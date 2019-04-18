defmodule IslandsEngine.Rules do
  @moduledoc """
  State machine that enforces the business rules over the business entities -
  Board, Coordinate, Island and Guesses.

  Defines when and which moves are valid for players.
  """

  alias __MODULE__

  defstruct state:    :initialized,
            player1:  :islands_not_set,
            player2:  :islands_not_set

  @spec new() :: %Rules{}
  def new, do: %Rules{}

  @spec check(%Rules{}, any) :: {:ok, %Rules{}} | :error
  def check(%Rules{state: :initialized} = rules, :add_player), do:
    {:ok, %Rules{rules | state: :players_set}}

  def check(%Rules{state: :players_set} = rules, {:position_islands, player}) do
    case Map.fetch!(rules, player) do
      :islands_set -> :error
      :islands_not_set -> {:ok, rules}
    end
  end

  def check(%Rules{state: :players_set} = rules, {:set_islands, player}) do
    rules = Map.put(rules, player, :islands_set)
    case both_players_islands_set?(rules) do
      true  ->  {:ok, %Rules{rules | state: :player1_turn}}
      false ->  {:ok, rules}
    end
  end

  def check(%Rules{state: :player1_turn} = rules, {:guess_coordinate, :player1}), do:
    {:ok, %Rules{rules | state: :player2_turn}}

  def check(%Rules{state: :player2_turn} = rules, {:guess_coordinate, :player2}), do:
    {:ok, %Rules{rules | state: :player1_turn}}

  def check(%Rules{state: :player1_turn} = rules, {:win_check, guess_result}) do
    case guess_result do
      :no_win -> {:ok, rules}
      :win    -> {:ok, %Rules{rules | state: :game_over}}
    end
  end

  def check(%Rules{state: :player2_turn} = rules, {:win_check, win_or_not}) do
    case win_or_not do
      :no_win -> {:ok, rules}
      :win    -> {:ok, %Rules{rules | state: :game_over}}
    end
  end

  def check(_state, _action), do: :error

  @spec both_players_islands_set?(%Rules{}) :: boolean
  defp both_players_islands_set?(rules), do:
    rules.player1 == :islands_set and rules.player2 == :islands_set

end
