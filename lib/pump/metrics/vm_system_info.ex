defmodule Pump.Metrics.VMSystemInfo do
  @moduledoc """
  TODO
  https://github.com/deadtrickster/prometheus.erl/blob/master/src/collectors/vm/prometheus_vm_memory_collector.erl

  """

  @system_info_items ~w[
    dirty_cpu_schedulers
    dirty_cpu_schedulers_online
    dirty_io_schedulers
    ets_limit
    logical_processors
    logical_processors_available
    logical_processors_online
    port_count
    port_limit
    process_count
    process_limit
    schedulers
    schedulers_online
    smp_support
    threads
    thread_pool_size
    time_correction
    atom_count
    atom_limit
  ]

  def metrics() do
    for item <- @system_info_items do
      system_info_item = String.to_atom(item)
      stats_item = "erlang_vm_" <> item
      {stats_item, [], :erlang.system_info(system_info_item)}
    end
  end
end
