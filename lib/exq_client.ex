defmodule ExqClient do
  require Record
  Record.defrecord :state, State, [:pid]

  def start_link(opts \\ []) do
    :gen_server.start_link({:local, :exq}, Exq.Enqueuer, opts, [])
  end

  def stop(pid) do
    :gen_server.call(:exq, {:stop})
  end

  def enqueue(queue, worker, args) do 
    :gen_server.call(:exq, {:enqueue, queue, worker, args})
  end

end
