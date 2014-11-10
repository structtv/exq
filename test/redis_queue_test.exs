Code.require_file "test_helper.exs", __DIR__

defmodule Exq.RedisQueueTest do
  use ExUnit.Case

  setup_all do
    TestRedis.setup
    on_exit fn ->
      TestRedis.teardown
    end
  end

  setup do
    :ets.new(:workers, [:named_table, :set, :public, {:read_concurrency, true}])
    :ok
  end

 
  test "enqueue/dequeue single queue" do
    Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    deq = Exq.RedisQueue.dequeue(:testredis, "test", "default")
    assert deq != :none 
    assert Exq.RedisQueue.dequeue(:testredis, "test", "default") == :none
  end
  
  test "enqueue/dequeue multi queue" do
    Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test", "myqueue", "MyWorker", [])
    assert Exq.RedisQueue.dequeue(:testredis, "test", ["default", "myqueue"]) != :none
    assert Exq.RedisQueue.dequeue(:testredis, "test", ["default", "myqueue"]) != :none
    assert Exq.RedisQueue.dequeue(:testredis, "test", ["default", "myqueue"]) == :none
  end

  test "creates and returns a jid" do
    jid = Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    assert jid != nil

    job_str = Exq.RedisQueue.dequeue(:testredis, "test", "default")
    job = Poison.decode!(job_str, as: Exq.Job)
    assert job.jid == jid
  end

  test "should not dequeue a task when the max number of workers for a queue are running" do
    Exq.RedisQueue.enqueue(:testredis, "test123", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test123", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test123", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test123", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test123", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test123", "default", "MyWorker", [])
    :ets.insert(:workers, {"default", 5})
    {queue, _} = Exq.RedisQueue.dequeue(:testredis, "test123", [{"default", 5}])
    assert queue == :none
  end

  test "should dequeue a task when the max number of workers for a queue are not running" do
    Exq.RedisQueue.enqueue(:testredis, "test123", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test123", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test123", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test123", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test123", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test123", "default", "MyWorker", [])
    :ets.insert(:workers, {"default", 0})
    job = Exq.RedisQueue.dequeue(:testredis, "test123", [{"default", 5}])
    assert job != :none
  end

end

