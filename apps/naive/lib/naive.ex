defmodule Naive do
  @moduledoc """
  Documentation for `Naive`.
  """

  # alias Streamer.Types.MarketTrade

  # def send_event(%MarketTrade{} = event) do
  #  GenServer.cast(:trader, event)
  # end

  def start_trading(symbol) do
  	symbol = String.upcase(symbol)
  	{:ok, _pid} = DynamicSupervisor.start_child(Naive.DynamicSymbolSupervisor, {Naive.SymbolSupervisor, symbol})
  end  
end
