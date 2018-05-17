defmodule Pump.Application do
  def start(_type, _args) do
    env = Application.get_all_env(:pump)

    children =
      if Keyword.get(env, :enabled, true) do
        [
          %{
            id: Pump,
            start: {Pump, :start_link, [env]}
          }
        ]
      else
        []
      end

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
