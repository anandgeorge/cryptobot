# Cryptobot

A crypto bot written in Elixir. It can be set up for training purposes so data is fetched from the exchanges but trades are mocked. This allows the user to get a good understanding about how a trading bot works without commiting any resources.

## Usage

Clone this repository. Run mix deps.get in each sub directory in apps i.e. binance_mock, naive and streamer. Then run the following commands to start trading in multiple cryptos.

```elixir
	cd apps/naive
	iex -S mix
```

Start the Observer to visualize the process and applications. Then start each application in sequence. Monitor their functioning.

```elixir
	iex(1)> (fn () -> :observer.start(); Streamer.start_streaming("XRPUSDT"); Naive.start_trading("XRPUSDT") end).()

	13:25:53.607 [info]  Starting new supervision tree to trade on XRPUSDT
	{:ok, #PID<0.360.0>}
	iex(2)> 
	13:25:55.682 [info]  Initializing new trader 1624953355672 for XRPUSDT
	 
	13:25:55.682 [info]  Start traders for XRPUSDT
	 
	13:25:55.850 [info]  The trader 1624953355672 is placing a BUY order for XRPUSDT @ 0.66150000, quantity: 30.22000000
	 
	13:25:58.103 [info]  The trader 1624953355672 is placing a SELL order for XRPUSDT @ 0.66200000, quantity: 30.22000000
	 
	13:26:38.552 [info]  Trader 1624953355672 finished, trader will now exit XRPUSDT
	 
	13:26:38.553 [info]  XRPUSDT trader finishing trading - restarting
	 
	13:26:38.553 [info]  Initializing new trader 1624953398553 for XRPUSDT
	 
	13:26:38.553 [info]  The trader 1624953398553 is placing a BUY order for XRPUSDT @ 0.66200000, quantity: 30.20000000
	 
	13:26:48.177 [info]  The trader 1624953398553 is placing a SELL order for XRPUSDT @ 0.66250000, quantity: 30.20000000
	 
	13:26:55.102 [info]  Trader 1624953398553 finished, trader will now exit XRPUSDT
	 
	13:26:55.103 [info]  XRPUSDT trader finishing trading - restarting
	 
	13:26:55.104 [info]  Initializing new trader 1624953415103 for XRPUSDT
	 
	13:26:55.234 [info]  The trader 1624953415103 is placing a BUY order for XRPUSDT @ 0.66240000, quantity: 30.18000000
	 
	13:26:57.193 [info]  The trader 1624953415103 is placing a SELL order for XRPUSDT @ 0.66290000, quantity: 30.18000000
	 
	13:27:14.905 [info]  Rebuy triggered for XRPUSDT by the trader 1624953415103
	 
	13:27:14.905 [info]  Starting new trader for XRPUSDT

	13:27:14.906 [info]  Initializing new trader 1624953434905 for XRPUSDT
	 
	13:27:14.906 [info]  The trader 1624953434905 is placing a BUY order for XRPUSDT @ 0.66160000, quantity: 30.22000000
	 
	13:27:14.907 [info]  The trader 1624953434905 is placing a SELL order for XRPUSDT @ 0.66210000, quantity: 30.22000000
```
