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
iex(1)> :observer.start()
:ok
iex(2)> Streamer.start_streaming("adausdt")
{:ok, #PID<0.342.0>}
iex(3)> Streamer.start_streaming("xrpusdt")   
{:ok, #PID<0.351.0>}
iex(4)> Naive.start_trading("adausdt")
{:ok, #PID<0.356.0>}
iex(5)> Naive.start_trading("xrpusdt")   
{:ok, #PID<0.365.0>}
iex(6)> 
11:47:25.878 [warn]  Trade finished, trader will now exit ADAUSDT
 
11:47:26.696 [warn]  Trade finished, trader will now exit XRPUSDT
 
11:48:07.071 [warn]  Trade finished, trader will now exit ADAUSDT
 
11:48:08.883 [warn]  Trade finished, trader will now exit XRPUSDT
 
11:48:15.443 [warn]  Trade finished, trader will now exit ADAUSDT
 
11:48:25.984 [warn]  Trade finished, trader will now exit ADAUSDT
```

With logs for each trade turned on

```elixir
iex(1)> :observer.start()
:ok
iex(2)> Streamer.start_streaming("adausdt")
{:ok, #PID<0.450.0>}
iex(3)> Streamer.start_streaming("xrpusdt")   
{:ok, #PID<0.458.0>}
iex(4)> Naive.start_trading("adausdt")
14:51:24.258 [info]  Starting new supervision tree to trade on ADAUSDT
{:ok, #PID<0.463.0>}
iex(5)>  
14:51:27.117 [info]  Start traders for ADAUSDT
 
14:53:06.098 [info]  Initializing new trader for ADAUSDT
 
14:53:16.573 [info]  Buy order filled, placing SELL order for ADAUSDT @ 1.34060000, quantity: 50
 
14:57:09.237 [info]  Trade finished, trader will now exit ADAUSDT
 
14:57:09.237 [info]  ADAUSDT trader finishing trading - restarting
 
14:57:09.237 [info]  Initializing new trader for ADAUSDT
 
14:57:09.237 [info]  Placing BUY order for ADAUSDT @ 1.34090000, quantity: 50
 
14:57:09.239 [info]  Buy order filled, placing SELL order for ADAUSDT @ 1.34190000, quantity: 50
 
15:00:45.692 [info]  Trade finished, trader will now exit ADAUSDT
 
15:00:45.693 [info]  ADAUSDT trader finishing trading - restarting
 
15:00:45.693 [info]  Initializing new trader for ADAUSDT
 
15:00:45.694 [info]  Placing BUY order for ADAUSDT @ 1.34200000, quantity: 50
 
15:00:46.485 [info]  Buy order filled, placing SELL order for ADAUSDT @ 1.34300000, quantity: 50
 
15:01:12.748 [info]  Trade finished, trader will now exit ADAUSDT
```

To view all logs use an anonymous function to call both functions simultaneously.

```elixir
(fn () -> Streamer.start_streaming("XRPUSDT"); Naive.start_trading("XRPUSDT") end).()

17:29:03.254 [info]  Starting new supervision tree to trade on XRPUSDT
{:ok, #PID<0.345.0>}
iex(5)> 
17:29:04.614 [debug] Trade event received XRPUSDT@0.62680000
 
17:29:05.413 [info]  Start traders for XRPUSDT
 
17:29:06.592 [debug] Trade event received XRPUSDT@0.62690000
 
17:29:06.592 [debug] Trade event received XRPUSDT@0.62690000
 
17:29:06.598 [info]  Placing BUY order for XRPUSDT @ 0.62680000, quantity: 50
 
17:29:06.600 [debug] BinanceMock subscribing to TRADE_EVENTS:XRPUSDT

```

To run multiple symbols and multiple traders for each symbol, start streaming for each and then start trading on each. Also start the observer to keep track of the processes.

```elixir
(fn () -> :observer.start(); Streamer.start_streaming("XRPUSDT"); Naive.start_trading("XRPUSDT"); Streamer.start_streaming("ADAUSDT"); Naive.start_trading("ADAUSDT") end).()
```
