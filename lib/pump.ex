defmodule Pump do
  use GenServer

  require Logger

  alias Pump.Metrics.{OSMon, VMMemory, VMStatistics, VMSystemInfo}
  alias Pump.InfluxDBWriter

  def start_link(env) do
    GenServer.start_link(__MODULE__, env)
  end

  def init(env) do
    Logger.debug("Start Pump with env: #{inspect(env)}")

    # required params
    base_url = Keyword.fetch!(env, :base_url)
    db_name = Keyword.fetch!(env, :db_name)
    send_interval = Keyword.fetch!(env, :send_interval)
    device_id = Keyword.fetch!(env, :device_id)

    # optional params
    user = Keyword.get(env, :user)
    password = Keyword.get(env, :password)
    custom_tags = Keyword.get(env, :custom_tags, [])
    query_params = Keyword.get(env, :query_params, [])

    http_client = InfluxDBWriter.http_client(base_url, db_name, user, password, query_params)
    tags = Keyword.merge([device_id: device_id], custom_tags)
    state = {http_client, tags, send_interval}

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
        Logger.warn("Error sending measurements to InfluxDB. Reason: #{inspect(error)}")
        {:error, error}

      other ->
        other
    end
  end
end
