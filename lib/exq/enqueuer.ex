defmodule Exq.Enqueuer do 
  use GenServer
  require Record
  Record.defrecord :state, State, [:redis, :busy_workers, :namespace, :queues]
  
##===========================================================
## gen server callbacks
##===========================================================

  def init(opts) do 
    host = Keyword.get(opts, :host, '127.0.0.1') 
    port = Keyword.get(opts, :port, 6379) 
    database = Keyword.get(opts, :database, 0)
    password = Keyword.get(opts, :password, '') 
    queues = Keyword.get(opts, :queues, ["default"]) 
    namespace = Keyword.get(opts, :namespace, "resque")
    reconnect_on_sleep = Keyword.get(opts, :reconnect_on_sleep, 100)
    {:ok, redis} = :eredis.start_link(host, port, database, password, reconnect_on_sleep)
    my_state = state(redis: redis, 
                      busy_workers: [], 
                      namespace: namespace, 
                      queues: queues)
    {:ok, my_state}
  end

  def handle_call({:enqueue, queue, worker, args}, _from, my_state) do 
    jid = Exq.RedisQueue.enqueue(my_state.redis, my_state.namespace, queue, worker, args) 
    {:reply, {:ok, jid}, my_state}
  end
  
  def handle_call({:stop}, _from, my_state) do
    { :stop, :normal, :ok, my_state }
  end
  

  def code_change(_old_version, my_state, _extra) do
    {:ok, my_state}
  end

  def terminate(_reason, _state) do 
    :ok
  end
  
  def handle_call(_request, _from, my_state) do 
    IO.puts("UKNOWN CALL")
    {:reply, :unknown, my_state}
  end  

  def handle_cast(_request, my_state) do 
    IO.puts("UKNOWN CAST")
    {:noreply, my_state}
  end  

##===========================================================
## Internal Functions
##===========================================================


  def dequeue(redis, namespace, queues) do 
    Exq.RedisQueue.dequeue(redis, namespace, queues) 
  end 


  def stop(pid) do 
  end
end
