# Exq

Exq is a job processing library compatible with Resque / Sidekiq for the [Elixir](http://elixir-lang.org) language.

Made to work with a Phoenix app.

## Example Usage:

Start worker process with:

`mix exq.run Appname`

To enqueue jobs:

In you client application add the following worker

```
children = [worker(ExqClient, [[host: Phoenix.Config.get!([:exq, :host]), port: Phoenix.Config.get!([:exq, :port]), namespace: Phoenix.Config.get!([:exq, :namespace])]])]
```

```elixir
{:ok, ack} = Exq.enqueue(pid, "default", "MyWorker", ["arg1", "arg2"])

{:ok, ack} = Exq.enqueue(pid, "default", "MyWorker/custom_method", [])
```

By default, the `perform` method will be called.  However, you can pass a method such as `MyWorker/custom_method`

Example Worker:
```elixir
defmodule MyWorker do
  def perform do
    # will get called if no custom method passed in
  end
end
```

## Contributors:

Benjamin Tan Wei Hao (benjamintanweihao)
Justin McNally  (j-mcnally)
