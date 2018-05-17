defmodule Pump do
  use GenServer

  require Logger

  # TODO behaviour
  alias Pump.Metrics.{OSMon, VMMemory, VMStatistics, VMSystemInfo}
  alias Pump.InfluxDBWriter

  def start_link(env) do
    GenServer.start_link(__MODULE__, env)
  end

  def init(env) do
    Logger.debug("Start Pump with env: #{inspect(env)}")

    # required params
    base_url = Keyword.get(env, :base_url)
    db_name = Keyword.get(env, :db_name)
    send_interval = Keyword.get(env, :send_interval)

    # optional params
    user = Keyword.get(env, :user)
    password = Keyword.get(env, :password)
    custom_tags = Keyword.get(env, :custom_tags, [])
    query_params = Keyword.get(env, :query_params, [])

    http_client = InfluxDBWriter.http_client(base_url, db_name, user, password, query_params)

    state = {http_client, custom_tags, send_interval}

    Process.send(self(), :send_stats, [])

    {:ok, state}
  end

  def handle_info(:send_stats, {http_client, custom_tags, send_interval} = state) do
    stats = gather_stats()
    send_stats(http_client, stats, custom_tags)

    Process.send_after(self(), :send_stats, send_interval)

    {:noreply, state}
  end

  def gather_stats() do
    VMMemory.metrics() ++ VMStatistics.metrics() ++ VMSystemInfo.metrics() ++ OSMon.metrics()
  end

  def send_stats(http_client, stats, custom_tags) do
    case Pump.InfluxDBWriter.write(http_client, stats, custom_tags) do
      {:error, error} ->
        {:error, error}

      _ ->
        :ok
    end
  end
end
