defmodule Pump.Metrics.VMStatistics do
  @moduledoc """
  TODO
  https://github.com/deadtrickster/prometheus.erl/blob/master/src/collectors/vm/prometheus_vm_memory_collector.erl
  erlang_vm_statistics_
  http://erlang.org/doc/man/erlang.html#statistics-1
  """

  def metrics() do
    {{:input, input}, {:output, output}} = :erlang.statistics(:io)
    {context_switches, _} = :erlang.statistics(:context_switches)
    [dirty_cpu_run_queue_length, dirty_io_run_queue_length] = dirty_stat()
    {number_of_gcs, words_reclaimed, _} = :erlang.statistics(:garbage_collection)
    word_size = :erlang.system_info(:wordsize)
    {reductions_total, _} = :erlang.statistics(:reductions)
    run_queues_length = :erlang.statistics(:run_queue)
    {runtime, _} = :erlang.statistics(:runtime)
    {wallclock_time, _} = :erlang.statistics(:wall_clock)

    [
      # Returns Input, which is the total number of bytes received through ports, and Output, which is the total number of bytes output to ports.
      {"erlang_vm_statistics_bytes_output_total", [], output},
      {"erlang_vm_statistics_bytes_received_total", [], input},
      # Returns the total number of context switches since the system started.
      {"erlang_vm_statistics_context_switches", [], context_switches},
      #  values for the dirty CPU run queue and the dirty IO run queue follow (in that order) at the end
      {"erlang_vm_statistics_dirty_cpu_run_queue_length", [], dirty_cpu_run_queue_length},
      {"erlang_vm_statistics_dirty_io_run_queue_length", [], dirty_io_run_queue_length},
      # dodane
      {"erlang_vm_statistics_garbage_collection_number_of_gcs", [], number_of_gcs},
      # dodane
      {"erlang_vm_statistics_garbage_collection_bytes_reclaimed", [],
       words_reclaimed * word_size},
      # dodane
      {"erlang_vm_statistics_garbage_collection_words_reclaimed", [], words_reclaimed},
      # dodane
      {"erlang_vm_statistics_reductions_total", [], reductions_total},
      # Returns the total length of all normal run-queues. That is, the number of processes and ports that are ready to run on all available normal run-queues. Dirty run queues are not part of the result.
      {"erlang_vm_statistics_run_queues_length", [], run_queues_length},
      {"erlang_vm_statistics_runtime_milliseconds", [], runtime},
      {"erlang_vm_statistics_wallclock_time_milliseconds", [], wallclock_time}
    ]
  end

  defp dirty_stat() do
    schedulers_online = :erlang.system_info(:schedulers_online)
    run_queue_lengths = :erlang.statistics(:run_queue_lengths_all)

    if Enum.count(run_queue_lengths) > schedulers_online do
      Enum.take(run_queue_lengths, -2)
    else
      [0, 0]
    end
  end
end
