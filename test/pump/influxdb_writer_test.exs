defmodule Pump.InfluxDBWriterTest do
  use ExUnit.Case

  import Tesla.Mock

  alias Pump.InfluxDBWriter, as: W

  setup do
    mock(fn
      %{method: :post, url: "http://normal_request.com/write"} ->
        %Tesla.Env{
          status: 204
        }

      %{method: :post, url: "http://non_existent_db.com/write"} ->
        %Tesla.Env{
          body: %{"error" => "database not found: \"XXX\""},
          status: 404
        }

      %{method: :post, url: "invalid_url/write"} ->
        {:error, :no_scheme}

      %{method: :post, url: "http://server_error/write"} ->
        %Tesla.Env{
          body: %{"error" => "retention policy not found: dupa"},
          status: 500
        }

      %{method: :post, url: "http://authorization_failed/write"} ->
        %Tesla.Env{
          body: %{"error" => "authorization failed"},
          status: 401
        }
    end)

    :ok
  end

  @data [{"m1", [t1: 1], [f1: 1, f2: "dwa"]}]

  test "Send stats to db" do
    http_client = W.http_client("http://normal_request.com", "test_db", "u", "p", [])

    assert :ok == W.write(http_client, @data)
  end

  test "Send stats to nonexistent db" do
    http_client = W.http_client("http://non_existent_db.com", "test_db", "u", "p", [])

    assert {:error, "database not found: \"XXX\""} == W.write(http_client, @data)
  end

  test "Send stats to invalid URL" do
    http_client = W.http_client("invalid_url", "test_db", "u", "p", [])

    assert {:error, :no_scheme} == W.write(http_client, @data)
  end

  test "Send stats and handle server-side error" do
    http_client = W.http_client("http://server_error", "test_db", "u", "p", rp: "dupa")

    assert {:error, "retention policy not found: dupa"} == W.write(http_client, @data)
  end

  test "Send stats with invalid credentials" do
    http_client = W.http_client("http://authorization_failed", "test_db", "u", "p", rp: "dupa")

    assert {:error, "authorization failed"} == W.write(http_client, @data)
  end

  test "Stats should be converted to InfluxDB line protocol format" do
    assert W.data_to_line_protocol([], []) == ""

    assert W.data_to_line_protocol([{"m1", [], [f1: 1, f2: "dwa"]}], []) == "m1 f1=1,f2=dwa"

    assert W.data_to_line_protocol([{"m1", [t1: 1], [f1: 1, f2: "dwa"]}], t2: :t2) ==
             "m1,t1=1,t2=t2 f1=1,f2=dwa"

    assert W.data_to_line_protocol({"m1", [], [f1: 1, f2: "dwa"]}, []) == "m1 f1=1,f2=dwa"

    assert W.data_to_line_protocol({"m1", [], [f1: 1]}, []) == "m1 f1=1"

    assert W.data_to_line_protocol({"m1", [], [{:f1, "1"}, {:f2, "dwa"}]}, []) == "m1 f1=1,f2=dwa"

    assert W.data_to_line_protocol({"m1", [t1: 1, t2: "2", t3: :t3], [f1: 1]}, []) ==
             "m1,t1=1,t2=2,t3=t3 f1=1"

    assert W.data_to_line_protocol({"m1", [], [f1: 1], 12_343_657_456_456}, []) ==
             "m1 f1=1 12343657456456"

    assert W.data_to_line_protocol(
             [
               {"m1", [t1: 1, t2: "2", t3: :t3], [f1: 1]},
               {"m2", [t1: 1, t2: "2", t3: :t3], [f1: 1], 14345}
             ],
             []
           ) == "m1,t1=1,t2=2,t3=t3 f1=1\nm2,t1=1,t2=2,t3=t3 f1=1 14345"

    assert W.data_to_line_protocol({"m1", [], :Asdf}, []) == "m1 value=Asdf"
  end
end
