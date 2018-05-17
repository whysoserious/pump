defmodule Pump.Metrics.OSMon do
  # TODO docs

  def metrics() do
    # http://erlang.org/doc/man/cpu_sup.html
    nprocs = :cpu_sup.nprocs()
    avg1 = :cpu_sup.avg1()
    avg5 = :cpu_sup.avg5()
    avg15 = :cpu_sup.avg15()
    avg_util = :cpu_sup.util()
    {_, busy, non_busy, _} = :cpu_sup.util([:detailed])

    # http://erlang.org/doc/man/disksup.html

    disk_data = :disksup.get_disk_data()
    total_sizes = for {id, total_size, _} <- disk_data, do: {id, total_size}
    capacities = for {id, _, capacity} <- disk_data, do: {id, capacity}

    {_, allocated_memory, _} = :memsup.get_memory_data()

    memory_stats =
      for {field, value} <- :memsup.get_system_memory_data() do
        field = Enum.join(["erlang_mem_sup_", field])
        {field, [], value}
      end

    memory_stats ++
      [
        {"erlang_cpu_sup_nprocs", [], nprocs},
        {"erlang_cpu_sup_avg", [], [avg1: avg1, avg5: avg5, avg15: avg15, avg_util: avg_util]},
        {"erlang_cpu_sup_util", [], busy ++ non_busy},
        {"erlang_disk_sup_total_size", [], total_sizes},
        {"erlang_disk_sup_capacity", [], capacities},
        {"erlang_mem_sup_allocated_memory", [], allocated_memory}
      ]
  end
end
