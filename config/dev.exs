use Mix.Config

config :pump,
  enabled: true,
  base_url: "http://localhost:8086",
  db_name: "dust_dev",
  device_id: "proto6",
  user: "dust_test",
  password: "dust_test",
  custom_tags: [],
  query_params: [],
  send_interval: 5000

config :logger, level: :debug
