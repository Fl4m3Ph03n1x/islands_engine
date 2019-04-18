defmodule IslandsEngine.Island do
  @moduledoc """
  Defines an island - its coordinates as well as its type.
  """

  alias IslandsEngine.{Coordinate, Island}

  @type shape :: :square | :atoll | :dot | :l_shape | :s_shape
  @type coordinate :: {integer, integer}

  @enforce_keys [:coordinates, :hit_coordinates]
  defstruct [:coordinates, :hit_coordinates]

  @spec new(any(), %Coordinate{}) :: {:ok, %Island{}} | {:error, any}
  def new(type, %Coordinate{} = upper_left) do
    with  [_|_] <- offsets = offsets(type),
          %MapSet{} <- coords = add_coordinates(offsets, upper_left)
    do
      {:ok, %Island{coordinates: coords, hit_coordinates: MapSet.new()}}
    else
      error -> error
    end
  end

  @spec offsets(shape) :: [tuple] | {:error, :invalid_island_type}
  defp offsets(:square), do: [{0, 0}, {0, 1}, {1, 0}, {1, 1}]
  defp offsets(:atoll), do: [{0, 0}, {0, 1}, {1, 1}, {2, 1}, {2, 0}]
  defp offsets(:dot), do: [{0, 0}]
  defp offsets(:l_shape), do: [{0, 0}, {1, 0}, {2, 0}, {2, 1}]
  defp offsets(:s_shape), do: [{0, 1}, {0, 2}, {1, 0}, {1, 1}]
  defp offsets(_), do: {:error, :invalid_island_type}

  @spec add_coordinates([tuple], %Coordinate{}) :: MapSet | {:error, :invalid_coordinate}
  defp add_coordinates(offsets, upper_left) do
    Enum.reduce_while(offsets, MapSet.new(), fn(offset, acc) ->
      add_coordinate(acc, upper_left, offset)
    end)
  end

  @spec add_coordinate(MapSet, %Coordinate{}, coordinate) ::
    {:cont, MapSet} | {:halt, {:error, :invalid_coordinate}}
  defp add_coordinate(
    coordinates,
    %Coordinate{row: row, col: col},
    {row_offset, col_offset}
  ) do
    case Coordinate.new(row + row_offset, col + col_offset) do
      {:ok, coord} ->
        {:cont, MapSet.put(coordinates, coord)}
      {:error, :invalid_coordinate} ->
        {:halt, {:error, :invalid_coordinate}}
    end
  end

  @spec overlaps?(%Island{}, %Island{}) :: boolean
  def overlaps?(existing_island, new_island), do:
    not MapSet.disjoint?(existing_island.coordinates, new_island.coordinates)

  @spec guess(%Island{}, %Coordinate{}) :: {:hit, %Island{}} | :miss
  def guess(island, coord) do
    if MapSet.member?(island.coordinates, coord) do
      new_hits = MapSet.put(island.hit_coordinates, coord)
      {:hit, %{island | hit_coordinates: new_hits}}
    else
      :miss
    end
  end

  @spec forested?(%Island{}) :: boolean
  def forested?(island), do:
    MapSet.equal?(island.coordinates, island.hit_coordinates)

  @spec types() :: [shape]
  def types, do: [:atoll, :dot, :l_shape, :s_shape, :square]
end
