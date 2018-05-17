defmodule Pump.Metrics.VMMemory do
  @moduledoc """
  TODO
  https://github.com/deadtrickster/prometheus.erl/blob/master/src/collectors/vm/prometheus_vm_memory_collector.erl
  http://erlang.org/doc/man/erlang.html#memory-1
  """

  def metrics() do
    [
      total: total,
      processes: processes,
      processes_used: processes_used,
      system: system,
      atom: atom,
      atom_used: atom_used,
      binary: binary,
      code: code,
      ets: ets
    ] = :erlang.memory()

    dets_tables_count = Enum.count(:dets.all())

    ets_tables_count = Enum.count(:ets.all())

    [
      # The total amount of memory currently allocated. This is the same as the sum of the memory size for processes and system.
      {"erlang_vm_memory_total", [], total},
      # atom_used:  The total amount of memory currently used for atoms. This memory is part of the memory presented as atom memory.
      # atom free The total amount of memory currently allocated for atoms. This memory is part of the memory presented as system memory - atom_used
      {"erlang_vm_memory_atom_bytes_total", [], [used: atom_used, free: atom - atom_used]},
      # system: The total amount of memory currently allocated for the emulator that is not directly related to any Erlang process. Memory presented as processes is not included in this memory. instrument(3) can be used to get a more detailed breakdown of what memory is part of this type.
      # The total amount of memory currently allocated for the Erlang processes.
      {"erlang_vm_memory_bytes_total", [], [system: system, processes: processes]},
      # Number of all open tables on this node. TODO
      {"erlang_vm_memory_dets_tables", [], dets_tables_count},
      # Number of all tables at the node TODO
      {"erlang_vm_memory_ets_tables", [], ets_tables_count},
      # processes

      # The total amount of memory currently allocated for the Erlang processes.
      # processes_used

      # The total amount of memory currently used by the Erlang processes. This is part of the memory presented as processes memory.

      {"erlang_vm_memory_processes_bytes_total", [],
       [used: processes_used, free: processes - processes_used]},
      {"erlang_vm_memory_system_bytes_total", [],
       [
         # The total amount of memory currently allocated for atoms. This memory is part of the memory presented as system memory.
         atom: atom,
         # The total amount of memory currently allocated for binaries
         binary: binary,
         # The total amount of memory currently allocated for Erlang code.
         code: code,
         # The total amount of memory currently allocated for ETS tables.
         ets: ets,
         # The total amount of memory currently allocated for the emulator that is not directly related to any Erlang process.
         system: system,
         #
         other: system - atom - binary - code - ets
       ]}
    ]
  end
end

[
  total: 27_202_080,
  processes: 5_564_376,
  processes_used: 5_564_376,
  system: 21_637_704,
  atom: 512_625,
  atom_used: 491_310,
  binary: 144_992,
  code: 13_276_499,
  ets: 877_928
]
