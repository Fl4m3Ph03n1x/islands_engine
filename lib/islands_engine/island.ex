defmodule IslandsEngine.Island do
  @moduledoc """
  Defines an island - its coordinates as well as its type.
  """

  alias IslandsEngine.{Coordinate, Island}

  @type shape :: :square | :atoll | :dot | :l_shape | :s_shape
  @type cord_offset :: {integer, integer}

  @enforce_keys [:coordinates, :hit_coordinates]
  defstruct [:coordinates, :hit_coordinates]

  @type t :: %__MODULE__{
    coordinates:      MapSet.t,
    hit_coordinates:  MapSet.t
  }

  @spec new(any(), Coordinate.t) :: {:ok, Island.t} | {:error, any}
  def new(type, %Coordinate{} = upper_left) do
    with  [_|_]         <- offsets = offsets(type),
          {:ok, coords} <- add_coordinates(offsets, upper_left)
    do
      {:ok, %Island{coordinates: coords, hit_coordinates: MapSet.new()}}
    end
  end

  @spec offsets(shape) :: [tuple] | {:error, :invalid_island_type}
  defp offsets(:square), do: [{0, 0}, {0, 1}, {1, 0}, {1, 1}]
  defp offsets(:atoll), do: [{0, 0}, {0, 1}, {1, 1}, {2, 1}, {2, 0}]
  defp offsets(:dot), do: [{0, 0}]
  defp offsets(:l_shape), do: [{0, 0}, {1, 0}, {2, 0}, {2, 1}]
  defp offsets(:s_shape), do: [{0, 1}, {0, 2}, {1, 0}, {1, 1}]
  defp offsets(_), do: {:error, :invalid_island_type}

  @spec add_coordinates([tuple], Coordinate.t) ::
    {:ok, MapSet.t} | {:error, :invalid_coordinate}
  defp add_coordinates(offsets, upper_left) do
    res = Enum.reduce_while(offsets, MapSet.new(), fn(offset, acc) ->
      add_coordinate(acc, upper_left, offset)
    end)

    case res do
      {:error, reason}  -> {:error, reason}
      map               -> {:ok, map}
    end
  end

  @spec add_coordinate(MapSet.t, Coordinate.t, cord_offset) ::
    {:cont, MapSet.t} | {:halt, {:error, :invalid_coordinate}}
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

  @spec overlaps?(Island.t, Island.t) :: boolean
  def overlaps?(existing_island, new_island), do:
    not MapSet.disjoint?(existing_island.coordinates, new_island.coordinates)

  @spec guess(Island.t, Coordinate.t) :: {:hit, Island.t} | :miss
  def guess(island, coord) do
    if MapSet.member?(island.coordinates, coord) do
      new_hits = MapSet.put(island.hit_coordinates, coord)
      {:hit, %{island | hit_coordinates: new_hits}}
    else
      :miss
    end
  end

  @spec forested?(Island.t) :: boolean
  def forested?(island), do:
    MapSet.equal?(island.coordinates, island.hit_coordinates)

  @spec types() :: [shape]
  def types, do: [:atoll, :dot, :l_shape, :s_shape, :square]
end
