defmodule Streamer do
  @moduledoc """
  Documentation for `Streamer`.
  """
  alias Streamer.DynamicStreamerSupervisor

  def start_streaming(symbol) do
    # Streamer.Binance.start_link(symbol)
    symbol
    |> String.upcase()
    |> DynamicStreamerSupervisor.start_streaming()
  end

  def stop_streaming(symbol) do
    symbol
    |> String.upcase()
    |> DynamicStreamerSupervisor.stop_streaming()
  end
end
