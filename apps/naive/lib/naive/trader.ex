defmodule Naive.Trader do
	use GenServer, restart: :temporary
	require Logger
	alias Streamer.Types.MarketTrade, as: MarketTrade
	alias Naive.Types.MyTrade, as: State
	alias Decimal, as: D

	@binance_client Application.compile_env(:naive, :binance_client)

	defmodule State do
		@enforce_keys [:symbol, :profit_interval, :tick_size]
		defstruct [
		  :symbol,
		  :buy_order,
		  :sell_order,
		  :profit_interval,
		  :tick_size
		]
	end

	def start_link(%State{} = state) do
		GenServer.start_link(__MODULE__, state)
	end

	def init(%State{symbol: symbol} = state) do
		symbol = String.upcase(symbol)
		Logger.info("Initializing new trader for #{symbol}")
		# tick_size = fetch_tick_size(symbol)
		Phoenix.PubSub.subscribe(
			Streamer.PubSub,
			"TRADE_EVENTS:#{symbol}"
		)
#		{:ok,
#			%State{
#				symbol: symbol,
#				profit_interval: profit_interval,
#				tick_size: tick_size
#			}
#		}
		{:ok, state}
	end

	def handle_info(
			%MarketTrade{price: price}, 
			%State{symbol: symbol, buy_order: nil} = state
		) do
		# quantity = "100"
		quantity = "50"
		Logger.info("Placing BUY order for #{symbol} @ #{price}, quantity: #{quantity}")

		{:ok, %Binance.OrderResponse{} = order} = 
			# Binance.order_limit_buy(symbol, quantity, price, "GTC")
			@binance_client.order_limit_buy(symbol, quantity, price, "GTC")
		new_state = %{state | buy_order: order}
		Naive.Leader.notify(:trader_state_updated, new_state)
		{:noreply, new_state}
	end

	def handle_info(
			%MarketTrade{
				buyer_order_id: order_id,
				quantity: quantity
			},
			%State{
				symbol: symbol, 
				buy_order: %Binance.OrderResponse{
					price: buy_price,
					order_id: order_id,
					orig_qty: quantity
				},
				profit_interval: profit_interval,
				tick_size: tick_size
			} = state
		) do
		sell_price = calculate_sell_price(buy_price, profit_interval, tick_size)
		
		Logger.info(
			"Buy order filled, placing SELL order for " <>
			"#{symbol} @ #{sell_price}, quantity: #{quantity}"
		)
		{:ok, %Binance.OrderResponse{} = order} = 
			# Binance.order_limit_sell(symbol, quantity, sell_price, "GTC")
			@binance_client.order_limit_sell(symbol, quantity, sell_price, "GTC")
		new_state = %{state | sell_order: order}
		Naive.Leader.notify(:trader_state_updated, new_state)
		{:noreply, new_state}
	end

	def handle_info(
			%MarketTrade{
				seller_order_id: order_id,
				quantity: quantity
			},
			%State{
				sell_order: %Binance.OrderResponse{
					order_id: order_id,
					orig_qty: quantity
				},
				symbol: symbol
			} = state
		) do
		Logger.info("Trade finished, trader will now exit #{symbol}")
		{:stop, :normal, state}
	end

	def handle_info(%MarketTrade{}, state) do
		{:noreply, state}
	end

	defp calculate_sell_price(buy_price, profit_interval, tick_size) do
		fee = "1.001"

		original_price = D.mult(buy_price, fee)

		net_target_price = 
			D.mult(
				original_price,
				D.add("1.0", profit_interval)
			)

		gross_target_price = D.mult(net_target_price, fee)

		D.to_string(
			D.mult(
				D.div_int(gross_target_price, tick_size),
				tick_size
			),
			:normal
		)
	end

#	defp fetch_tick_size(symbol) do
#		# Binance.get_exchange_info()
#		@binance_client.get_exchange_info()
#		|> elem(1)
#		|> Map.get(:symbols)
#		|> Enum.find(&(&1["symbol"] == symbol))
#		|> Map.get("filters")
#		|> Enum.find(&(&1["filterType"] == "PRICE_FILTER"))
#		|> Map.get("tickSize")
#	end
end