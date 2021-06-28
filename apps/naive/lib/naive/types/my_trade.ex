defmodule Naive.Types.MyTrade do
	@enforce_keys [:symbol, :profit_interval, :tick_size]
	defstruct [
		:symbol,
		:buy_order,
		:sell_order,
		:profit_interval,
		:tick_size
	]
end