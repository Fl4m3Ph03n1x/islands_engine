defmodule IslandsEngine.Board do
  @moduledoc """
  Represents a board where the players will put islands and make guesses.
  """

  alias IslandsEngine.{Coordinate, Island}

  @type board :: map
  @type guess_response ::
    {:hit | :miss, %Island{} | :none, :win | :no_win, board}

  @spec new() :: board
  def new, do: %{}

  @spec position_island(board, atom, %Island{})
    :: board | {:error, :overlapping_island}
  def position_island(board, key, %Island{} = island) do
    overlaps_existing_island? = Enum.any?(board, fn {a_key, an_island} ->
        a_key != key and Island.overlaps?(an_island, island)
      end)

    if overlaps_existing_island? do
      {:error, :overlapping_island}
    else
      Map.put(board, key, island)
    end
  end

  @spec all_islands_positioned?(map) :: boolean
  def all_islands_positioned?(board), do:
    Enum.all?(Island.types, &(Map.has_key?(board, &1)))

  @spec guess(map, %Coordinate{}) :: guess_response
  def guess(board, %Coordinate{} = coord) do
    board
    |> hit_all_islands(coord)
    |> guess_response(board)
  end

  @spec hit_all_islands(map, %Coordinate{}) ::
    {Island.shape, %Island{}} | :miss
  defp hit_all_islands(board, %Coordinate{} = coord) do
    hit_island = fn {key, island} ->
      case Island.guess(island, coord) do
        {:hit, island}  ->  {key, island}
        :miss           ->  false
      end
    end

    Enum.find_value(board, :miss, hit_island)
  end

  @spec guess_response({Island.shape, %Island{}} | :miss, map) ::
    guess_response
  defp guess_response({key, island}, board) do
    board = %{board | key => island}
    {:hit, forest_check(board, key), win_check(board), board}
  end

  defp guess_response(:miss, board), do: {:miss, :none, :no_win, board}

  @spec forest_check(map, Island.shape) :: Island.shape | :none
  defp forest_check(board, key) do
    forested? =
      board
      |> Map.fetch!(key)
      |> Island.forested?()

    if forested? do
      key
    else
      :none
    end
  end

  @spec win_check(map) :: :win | :no_win
  defp win_check(board) do
    all_forested? = Enum.all?(board, fn {_key, island} ->
      Island.forested?(island)
    end)

    if all_forested? do
      :win
    else
      :no_win
    end
  end
end
