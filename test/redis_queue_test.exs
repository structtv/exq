Code.require_file "test_helper.exs", __DIR__

defmodule Exq.RedisQueueTest do
  use ExUnit.Case

  setup_all do
    :ets.new(:workers, [:named_table, :set, :public, {:read_concurrency, true}])
    TestRedis.setup
    on_exit fn ->
      TestRedis.teardown
    end
  end

  setup do
    TestRedis.flush_all
    :ok
  end

 
  test "enqueue/dequeue single queue" do
    Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    deq = Exq.RedisQueue.dequeue(:testredis, "test", "default")
    assert deq != :none
    deq = Exq.RedisQueue.dequeue(:testredis, "test", "default")
    assert deq == :none
  end
  
  test "enqueue/dequeue multi queue" do
    Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test", "myqueue", "MyWorker", [])
    {queue, _} = Exq.RedisQueue.dequeue(:testredis, "test", [{"default", 10}, {"myqueue", 5}])
    assert queue != :none
    {queue, _} = Exq.RedisQueue.dequeue(:testredis, "test", [{"default", 10}, {"myqueue", 5}])
    assert queue != :none
    {queue, _} = Exq.RedisQueue.dequeue(:testredis, "test", [{"default", 10}, {"myqueue", 5}])
    assert queue == :none
  end

  test "should not dequeue a task when the max number of workers for a queue are running" do
    Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    :ets.insert(:workers, {"default", 5})
    {queue, _} = Exq.RedisQueue.dequeue(:testredis, "test", [{"default", 5}])
    assert queue == :none
  end

  test "should dequeue a task when the max number of workers for a queue are not running" do
    Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    Exq.RedisQueue.enqueue(:testredis, "test", "default", "MyWorker", [])
    :ets.insert(:workers, {"default", 0})
    {queue, _} = Exq.RedisQueue.dequeue(:testredis, "test", [{"default", 5}])
    assert queue != :none
  end

end

