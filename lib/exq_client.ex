defmodule ExqClient do

  def start(opts \\ []) do
    :gen_server.start(Exq.Enqueuer, opts, [])
  end

  def start_link(opts \\ []) do
    :gen_server.start_link(Exq.Enqueuer, opts, [])
  end

  def stop(pid) do
    :gen_server.call(pid, {:stop})
  end

  def enqueue(pid, queue, worker, args) do 
    :gen_server.call(pid, {:enqueue, queue, worker, args})
  end

end
