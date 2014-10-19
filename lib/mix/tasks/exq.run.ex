defmodule Mix.Tasks.Exq.Run do
  use Mix.Task

  @shortdoc "Starts the Exq worker"

  def run(args) do
    {opts, args, _} = OptionParser.parse args,
      switches: []
    app = parse_app(args)
    app.start(nil)
    host = Phoenix.Config.get!([:exq, :host])
    port = Phoenix.Config.get!([:exq, :port])
    namespace = Phoenix.Config.get!([:exq, :namespace])

    {:ok, pid} = Exq.start([host: host, port: port, namespace: namespace])    
    IO.puts "Started Exq with redis options: Host: #{host}, Port: #{port}, Namespace: #{namespace}"
    :timer.sleep(:infinity)
  end

  def parse_app([h|t]) when is_binary(h) and h != "" do
    {Module.concat([h]), t}
  end

  def parse_app([h|t]) when is_atom(h) and h != :"" do
    {h, t}
  end

  def parse_app(_) do
    raise Mix.Error, message: "invalid arguments, expected an applicaiton as first argument"
  end

end