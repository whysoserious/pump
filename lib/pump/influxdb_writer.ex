defmodule Pump.InfluxDBWriter do
  use Tesla

  require Logger

  def write(http_client, data, custom_tags \\ []) do
    Logger.debug("Send #{Enum.count(data)} measurements")

    data
    |> data_to_line_protocol(custom_tags)
    |> post_data(http_client)
  end

  def http_client(base_url, db_name, user, password, query_params) do
    query_params =
      [db: db_name, u: user, p: password]
      |> Keyword.merge(query_params)
      |> Enum.filter(fn {_, v} -> v end)

    Tesla.build_client([
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Query, query_params},
      {Tesla.Middleware.JSON, []}
    ])
  end

  def post_data(""), do: :ok

  def post_data(payload, http_client) do
    response = post(http_client, "/write", payload)

    result =
      case response do
        {:ok, %{status: 204}} -> :ok
        {:ok, %{body: %{"error" => error_msg}}} -> {:error, error_msg}
        {:ok, %{body: body}} -> {:error, body}
        {:error, error} -> {:error, error}
      end

    case result do
      {:error, _} ->
        Logger.debug("Error HTTP response: #{inspect(response)}")

      _ ->
        nil
    end

    result
  end

  def data_to_line_protocol(data, custom_tags) when is_list(data) do
    data
    |> Enum.map(&data_to_line_protocol(&1, custom_tags))
    |> Enum.join("\n")
  end

  def data_to_line_protocol({measurement, tags, fields, timestamp}, custom_tags) do
    data_to_line_protocol(measurement, tags ++ custom_tags, fields, timestamp)
  end

  def data_to_line_protocol({measurement, tags, fields}, custom_tags) do
    data_to_line_protocol(measurement, tags ++ custom_tags, fields)
  end

  def data_to_line_protocol(measurement, [], fields, timestamp) do
    fields = join_keyword_lists(fields)
    Enum.join([measurement, " ", fields, " ", timestamp])
  end

  def data_to_line_protocol(measurement, tags, fields, timestamp) do
    tags = join_keyword_lists(tags)
    fields = join_keyword_lists(fields)
    Enum.join([measurement, ",", tags, " ", fields, " ", timestamp])
  end

  def data_to_line_protocol(measurement, [], fields) do
    fields = join_keyword_lists(fields)
    Enum.join([measurement, " ", fields])
  end

  def data_to_line_protocol(measurement, tags, fields) do
    tags = join_keyword_lists(tags)
    fields = join_keyword_lists(fields)
    Enum.join([measurement, ",", tags, " ", fields])
  end

  def join_keyword_lists([{k, v} | []]), do: Enum.join([k, "=", v])

  def join_keyword_lists([{k, v} | tail]) do
    Enum.join([k, "=", v, ",", join_keyword_lists(tail)])
  end

  def join_keyword_lists(v), do: Enum.join(["value=", v])
end
