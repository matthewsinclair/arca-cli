defmodule Arca.CLI.History do
  @moduledoc """
  Holds onto state for the CLI.
  """

  use GenServer
  require Logger

  defmodule CLIHistory do
    defstruct history: []
  end

  @type state :: %CLIHistory{history: [String.t()]}

  # Client API

  @doc """
  Start the State GenServer.

  ## Parameters
    - `initial_state` (optional): The initial state of the GenServer. Defaults to `%CLIHistory{}`.

  ## Examples
      iex> is_pid(Process.whereis(Arca.CLI.History))
      true
  """
  def start_link(initial_state \\ %CLIHistory{}) do
    # Logger.info("#{__MODULE__}.start_link: #{inspect(initial_state)}")
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  @doc """
  Get the State struct.

  ## Examples
      iex> # Arca.CLI.History.start_link() is already started
      iex> %Arca.CLI.History.CLIHistory{} = Arca.CLI.History.state()
  """
  def state do
    GenServer.call(__MODULE__, :state)
  end

  @doc """
  Push a new command onto the front of the command history.

  ## Parameters
    - `cmd`: The command to push onto the history. It should be a binary string.

  ## Examples
      iex> Arca.CLI.History.flush_history()
      iex> Arca.CLI.History.push_cmd("echo 'Hello World'")
      [{0, "echo 'Hello World'"}]
  """
  def push_cmd(cmd) when is_binary(cmd) do
    GenServer.call(__MODULE__, {:push_cmd, cmd})
  end

  def push_cmd(cmd), do: push_cmd(inspect(cmd))

  @doc """
  Get the current history length.

  ## Examples
      iex> # Arca.CLI.History.start_link() is already started
      iex> Arca.CLI.History.flush_history()
      iex> Arca.CLI.History.push_cmd("echo 'Hello World'")
      iex> Arca.CLI.History.hlen()
      1
  """
  def hlen do
    GenServer.call(__MODULE__, :hlen)
  end

  @doc """
  Get the list of recent commands in reverse order.

  ## Examples
      iex> # Arca.CLI.History.start_link() is already started
      nil
      iex> Arca.CLI.History.flush_history()
      []
      iex> Arca.CLI.History.push_cmd("echo 'Hello World'")
      [{0, "echo 'Hello World'"}]
      iex> Arca.CLI.History.push_cmd("ls -l")
      [{1, "ls -l"}, {0, "echo 'Hello World'"}]
      iex> Arca.CLI.History.history()
      [{0, "echo 'Hello World'"}, {1, "ls -l"}]
  """
  def history do
    GenServer.call(__MODULE__, :history)
  end

  @doc """
  Flush the history completely.

  ## Examples
      iex> # Arca.CLI.History.start_link() is already started
      iex> Arca.CLI.History.flush_history()
      iex> Arca.CLI.History.push_cmd("echo 'Hello World'")
      iex> Arca.CLI.History.flush_history()
      []
  """
  def flush_history do
    GenServer.call(__MODULE__, :flush_history)
  end

  # Server Callbacks

  @impl true
  def init(initial_state) do
    # Logger.info("#{__MODULE__}.init: #{inspect(initial_state)}")
    {:ok, initial_state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:push_cmd, cmd}, _from, state) do
    new_history = [{length(state.history), String.trim(cmd)} | state.history]
    new_state = %CLIHistory{history: new_history}
    {:reply, new_history, new_state}
  end

  @impl true
  def handle_call(:hlen, _from, state) do
    {:reply, length(state.history), state}
  end

  @impl true
  def handle_call(:history, _from, state) do
    {:reply, Enum.reverse(state.history), state}
  end

  @impl true
  def handle_call(:flush_history, _from, _state) do
    new_state = %CLIHistory{history: []}
    {:reply, [], new_state}
  end
end
