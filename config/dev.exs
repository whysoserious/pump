use Mix.Config

config :pump,
  enabled: true,
  base_url: "http://<some_ip>:<influx_port>",
  db_name: "grafana",
  user: "secret_user",
  password: "secret_password",
  custom_tags: [],
  query_params: [],
  send_interval: 5000

config :logger, level: :info
