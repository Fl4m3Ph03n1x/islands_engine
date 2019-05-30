defmodule IslandsEngine.Guesses do
  @moduledoc """
  Defines what a Guess is. Guesses can be misses or hits, depending if they
  miss or hit an island repectively.
  """

  alias IslandsEngine.{Coordinate, Guesses}

  @enforce_keys [:hits, :misses]
  defstruct [:hits, :misses]

  @type t :: %__MODULE__{
    hits:   MapSet.t,
    misses: MapSet.t
  }

  @spec new() :: Guesses.t
  def new, do: %Guesses{hits: MapSet.new(), misses: MapSet.new()}

  @spec add(Guesses.t, :hit | :miss, Coordinate.t) :: Guesses.t
  def add(%Guesses{} = guesses, :hit, %Coordinate{} = coord) do
    update_in(guesses.hits, &MapSet.put(&1, coord))
  end

  def add(%Guesses{} = guesses, :miss, %Coordinate{} = coord) do
    update_in(guesses.misses, &MapSet.put(&1, coord))
  end
end
