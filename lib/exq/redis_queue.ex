defmodule Exq.RedisQueue do 

  @default_queue "default"

  def enqueue(redis, namespace, queue, worker, args) do
    Exq.Redis.sadd!(redis, full_key(namespace, "queues"), queue)
    Exq.Redis.rpush!(redis, queue_key(namespace, queue),
      job_json(queue, worker, args))
  end

  def working(queue) do
    case :ets.lookup(:workers, queue) do
      [] ->
        :ets.insert(:workers, {queue, 1})
      [{_, working_count}] ->
        :ets.insert(:workers, {queue, working_count + 1})
    end
  end

  def finished(queue) do
    case :ets.lookup(:workers, queue) do
      [] ->
        :ets.insert(:workers, {queue, 0})
      [{_, working_count}] ->
        :ets.insert(:workers, {queue, working_count - 1})
    end
  end



  def dequeue(redis, namespace, queues) when is_list(queues) do 
    dequeue_random(redis, namespace, queues)
  end
  def dequeue(redis, namespace, queue) do 
    Exq.Redis.lpop!(redis, queue_key(namespace, queue))
  end

  defp full_key(namespace, key) do 
    "#{namespace}:#{key}"
  end

  defp queue_key(namespace, queue) do 
    full_key(namespace, "queue:#{queue}")
  end
  
  defp dequeue_random(redis, namespace, []) do 
    nil
  end

  defp dequeue_random(redis, namespace, queues) do
    queue_names = for q <- queues do
      {queue, _} = q
      queue
    end

    [h | rq]  = Exq.Shuffle.shuffle(queue_names)
    if can_run(queues, h) do
      case dequeue(redis, namespace, h) do
        nil -> dequeue_random(redis, namespace, rq)
        job -> {job, h}
      end
    else
      {:none, h}
    end
  end

  defp can_run(queues, h) do
    queueDict = Enum.into(queues, HashDict.new)
    case HashDict.fetch(queueDict, h) do
      {:ok, concurrency} ->
        # Concurrency limit set, check to see if pool is full
        pool_size = 0
        case :ets.lookup(:workers, h) do
          [] ->
            true
          [{_, working_count}] ->
            working_count < concurrency
        end
      _ ->
        false
    end
  end

  defp job_json(queue, worker, args) do
    job = Enum.into([{:queue, queue}, {:class, worker}, {:args, args}], HashDict.new)
    JSEX.encode!(job)
  end
end
