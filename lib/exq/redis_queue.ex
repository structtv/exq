defmodule Exq.RedisQueue do
  use Timex

  @default_queue "default"

  def find_job(redis, namespace, jid, queue) do
    jobs = Exq.Redis.lrange!(redis, queue_key(namespace, queue))

    finder = fn({j, idx}) ->
      job = Exq.Job.from_json(j)
      job.jid == jid
    end

    error = Enum.find(Enum.with_index(jobs), finder)

    case error do
      nil ->
        {:not_found, nil}
      _ ->
        {job, idx} = error
        {:ok, job, idx}
    end
  end

  def enqueue(redis, namespace, queue, worker, args) do
    {jid, job} = job_json(queue, worker, args)
    [{:ok, _}, {:ok, _}] = :eredis.qp(redis, [
      ["SADD", full_key(namespace, "queues"), queue],
      ["RPUSH", queue_key(namespace, queue), job]])
    jid
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

  def full_key(namespace, key) do
    "#{namespace}:#{key}"
  end

  def queue_key(namespace, queue) do
    full_key(namespace, "queue:#{queue}")
  end

  defp dequeue_random(redis, namespace, []) do
    nil
  end
  defp dequeue_random(redis, namespace, queues) do
    queue_names = for q <- queues do
      q = case q do
        {queue, count} -> 
          {queue, count} 
        queue ->
          {queue, nil}
      end
      q
    end

    [h | rq]  = Exq.Shuffle.shuffle(queue_names)
    {h, count} = h
    if can_run(queue_names, h) do
      case dequeue(redis, namespace, h) do
        nil -> dequeue_random(redis, namespace, rq)
        job -> job
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
          [{_, nil}] ->
            true
          [{_, working_count}] ->
            working_count < concurrency
        end
      _ ->
        false
    end
  end

  defp job_json(queue, worker, args) do
    jid = UUID.uuid4
    job = Enum.into([{:queue, queue}, {:class, worker}, {:args, args}, {:jid, jid}, {:enqueued_at, DateFormat.format!(Date.local, "{ISO}")}], HashDict.new)
    {jid, Exq.Json.encode(job)}
  end
end
