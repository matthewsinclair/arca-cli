defmodule Arca.CLI.HistorySupervisor do
  use Supervisor
  require Logger
  alias Arca.CLI.History

  def start_link(init_arg) do
    # Logger.info("#{__MODULE__}.start_link: #{inspect(init_arg)}")
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    # Logger.info("#{__MODULE__}.init: #{inspect(init_arg)}")

    children = [
      {Arca.CLI.History, %History.CLIHistory{}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
