defmodule Exq.Worker do 
  use GenServer
  require Record
  Record.defrecord :state, State, [:job, :queue]

  def start(job, queue) do
    :gen_server.start(__MODULE__, {job, queue}, [])
  end

  def work(pid) do 
    :gen_server.cast(pid, :work)
  end

##===========================================================
## gen server callbacks
##===========================================================

  def init({job, queue}) do
    {:ok, state(job: job, queue: queue)}
  end

  def handle_cast(:work, my_state) do
    IO.puts state(my_state, :job)
    job_dict = JSEX.decode!(state(my_state, :job))
    target = Dict.get(job_dict, "class")
    [mod | func_or_empty] = Regex.split(~r/\//, target)
    func = case func_or_empty do
      [] -> :perform
      [f] -> :erlang.binary_to_atom(f, :utf8)
    end
    args = Dict.get(job_dict, "args")
    dispatch_work(mod, func, args)
    {:stop, :normal, my_state}
  end

  def code_change(_old_version, my_state, _extra) do
    {:ok, my_state}
  end

  def terminate(_reason, my_state) do
    # Decrement queue worker
    Exq.RedisQueue.finished(state(my_state, :queue))
    :ok
  end

##===========================================================
## Internal Functions
##===========================================================
 
  def dispatch_work(worker_module, args) do
    dispatch_work(worker_module, :perform, args)
  end
  def dispatch_work(worker_module, method, args) do
    IO.puts "Running worker:: #{worker_module}, #{args}"
    :erlang.apply(String.to_atom("Elixir.#{worker_module}"), method, args)
  end
end
