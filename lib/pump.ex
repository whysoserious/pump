defmodule Pump do
  use GenServer

  require Logger

  alias Pump.Metrics.{OSMon, VMMemory, VMStatistics, VMSystemInfo}
  alias Pump.InfluxDBWriter

  def send_stats(pid, stats), do: send(pid, {:send_stats, stats})

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

    Process.send(self(), :gather_and_send_stats, [])

    {:ok, state}
  end

  def handle_info(:gather_and_send_stats, {_, _, send_interval} = state) do
    stats = gather_stats()
    send_stats(self(), stats)

    Process.send_after(self(), :gather_and_send_stats, send_interval)

    {:noreply, state}
  end

  def handle_info({:send_stats, stats}, {http_client, tags, _} = state) do
    send_stats(http_client, stats, tags)
    {:noreply, state}
  end

  defp gather_stats() do
    VMMemory.metrics() ++ VMStatistics.metrics() ++ VMSystemInfo.metrics() ++ OSMon.metrics()
  end

  defp send_stats(http_client, stats, tags) do
    case InfluxDBWriter.write(http_client, stats, tags) do
      {:error, error} ->
        Logger.warn("Error sending measurements to InfluxDB. Reason: #{inspect(error)}")
        {:error, error}

      other ->
        other
    end
  end
end
