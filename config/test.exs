use Mix.Config

config :pump, enabled: false

config :logger, level: :debug

config :tesla, Pump.InfluxDBWriter, adapter: Tesla.Mock
