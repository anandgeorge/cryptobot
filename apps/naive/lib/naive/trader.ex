defmodule Naive.Trader do
	use GenServer, restart: :temporary
	require Logger
	alias Streamer.Types.MarketTrade, as: MarketTrade
	alias Naive.Types.MyTrade, as: State
	alias Decimal, as: D

	@binance_client Application.compile_env(:naive, :binance_client)

	defmodule State do
		@enforce_keys [:id, :symbol, :budget, :buy_down_interval, :profit_interval, :rebuy_interval, :rebuy_notified, :tick_size]
		defstruct [
		  :id,
		  :symbol,
		  :budget,
		  :buy_order,
		  :sell_order,
		  :buy_down_interval,
		  :profit_interval,
		  :rebuy_interval,
		  :rebuy_notified,
		  :tick_size,
		  :step_size
		]
	end

	def start_link(%State{} = state) do
		GenServer.start_link(__MODULE__, state)
	end

	def init(%State{id: id, symbol: symbol} = state) do
		symbol = String.upcase(symbol)
		Logger.info("Initializing new trader #{id} for #{symbol}")
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
			%State{id: id, symbol: symbol, budget: budget, buy_order: nil, 
				buy_down_interval: buy_down_interval, tick_size: tick_size, step_size: step_size
			} = state
		) do
		# quantity = "100"
		# quantity = "50"
		quantity = calculate_quantity(budget, price, step_size)
		price = calculate_buy_price(price, buy_down_interval, tick_size)
		Logger.info("The trader #{id} is placing a BUY order for #{symbol} @ #{price}, quantity: #{quantity}")

		{:ok, %Binance.OrderResponse{} = order} = 
			# Binance.order_limit_buy(symbol, quantity, price, "GTC")
			@binance_client.order_limit_buy(symbol, quantity, price, "GTC")
		new_state = %{state | buy_order: order}
		Naive.Leader.notify(:trader_state_updated, new_state)
		{:noreply, new_state}
	end


	def handle_info(
			%MarketTrade{
				buyer_order_id: order_id
			},
			%State{
				buy_order: %Binance.OrderResponse{
					order_id: order_id,
					status: "FILLED"
				},
				sell_order: %Binance.OrderResponse{}
			} = state
		) do
		{:noreply, state}
	end

	def handle_info(
			%MarketTrade{
				buyer_order_id: order_id,
				# quantity: quantity
			},
			%State{
				id: id,
				symbol: symbol, 
				buy_order: %Binance.OrderResponse{
					price: buy_price,
					order_id: order_id,
					orig_qty: quantity,
					transact_time: timestamp
				} = buy_order,
				profit_interval: profit_interval,
				tick_size: tick_size
			} = state
		) do

		{:ok, %Binance.Order{} = current_buy_order} = @binance_client.get_order(symbol, timestamp, order_id)
		buy_order = %{buy_order | status: current_buy_order.status}

		{:ok, new_state} =
			if buy_order.status == "FILLED" do
				sell_price = calculate_sell_price(buy_price, profit_interval, tick_size)
				Logger.info("The trader #{id} is placing a SELL order for " <> "#{symbol} @ #{sell_price}, quantity: #{quantity}")
				{:ok, %Binance.OrderResponse{} = order} = 
				# Binance.order_limit_sell(symbol, quantity, sell_price, "GTC")
				@binance_client.order_limit_sell(symbol, quantity, sell_price, "GTC")
				{:ok, %{state | buy_order: buy_order, sell_order: order}}
			else
				Logger.info("Trader #{id} #{symbol} BUY order got partially filled")
				{:ok, %{state | buy_order: buy_order}}
			end
		Naive.Leader.notify(:trader_state_updated, new_state)
		{:noreply, new_state}
	end

	def handle_info(
			%MarketTrade{
				seller_order_id: order_id,
				# quantity: quantity
			},
			%State{
				id: id,
				symbol: symbol,
				sell_order: %Binance.OrderResponse{
					order_id: order_id,
					# orig_qty: quantity
					transact_time: timestamp
				} = sell_order,
				# symbol: symbol
			} = state
		) do
		{:ok, %Binance.Order{} = current_sell_order} = @binance_client.get_order(
				symbol, timestamp, order_id)
		sell_order = %{sell_order | status: current_sell_order.status}

		if sell_order.status == "FILLED" do
			Logger.info("Trader #{id} finished, trader will now exit #{symbol}")
			{:stop, :normal, state}
		else 
			Logger.info("Trader #{id} #{symbol} SELL order got partially filled")
			new_state = %{state | sell_order: sell_order}
			{:noreply, new_state}
		end
	end

	def handle_info(
			%MarketTrade{
				price: current_price
			},
			%State{
				id: id,
				symbol: symbol,
				buy_order: %Binance.OrderResponse{
					price: buy_price
				},
				rebuy_interval: rebuy_interval,
				rebuy_notified: false

			} = state
		) do
		if trigger_rebuy?(buy_price, current_price, rebuy_interval) do
			Logger.info("Rebuy triggered for #{symbol} by the trader #{id}")
			new_state = %{state | rebuy_notified: true}
			Naive.Leader.notify(:rebuy_triggered, new_state)
			{:noreply, new_state}
		else
			{:noreply, state}
		end
	end

	def handle_info(%MarketTrade{}, state) do
		{:noreply, state}
	end

	defp calculate_quantity(budget, price, step_size) do
		exact_target_quantity = D.div(budget, price)

		D.to_string(
			D.mult(
				D.div_int(exact_target_quantity, step_size), step_size
			),
			:normal
		)
	end

	defp calculate_buy_price(current_price, buy_down_interval, tick_size) do
		exact_buy_price = D.sub(current_price, D.mult(current_price, buy_down_interval))
		D.to_string(D.mult(D.div_int(exact_buy_price, tick_size), tick_size), :normal)
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

	defp trigger_rebuy?(buy_price, current_price, rebuy_interval) do
		rebuy_price =
			D.sub(buy_price, D.mult(buy_price, rebuy_interval))
			D.lt?(current_price, rebuy_price)
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