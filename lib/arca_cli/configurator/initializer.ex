defmodule Arca.Cli.Configurator.Initializer do
  @moduledoc """
  Delayed initializer for Arca.Cli configuration.

  This GenServer is responsible for performing configuration-related initialization
  tasks after the application has fully started. It helps prevent circular dependencies
  between applications by delaying operations that might require other applications
  to be running first.

  Tasks performed by the initializer:
  - Loading settings from Arca.Config
  - Registering callbacks with Arca.Config
  - Ensuring configuration is available for CLI commands
  """

  use GenServer
  require Logger

  # 500ms delay before initialization starts
  @initialization_delay 500

  # Client API

  @doc """
  Starts the initializer GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns the initialization status.
  """
  def status do
    case Process.whereis(__MODULE__) do
      nil -> {:error, :not_started}
      _pid -> GenServer.call(__MODULE__, :status)
    end
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    # Mark this process as being in initialization phase
    Arca.Cli.mark_initialization_phase()

    # Schedule delayed initialization
    Process.send_after(self(), :initialize, @initialization_delay)
    {:ok, %{initialized: false, initialization_time: nil}}
  end

  @impl true
  def handle_info(:initialize, _state) do
    # Logger.debug("Starting delayed CLI initialization")

    # Perform initialization tasks
    # start_time = System.monotonic_time(:millisecond)

    # Step 1: Load settings from Arca.Config
    load_settings_result =
      try do
        Arca.Cli.load_settings()
      rescue
        e ->
          Logger.error("Error loading settings during initialization: #{inspect(e)}")
          {:error, :initialization_failed, "Failed to load settings"}
      end

    # Step 2: Register callbacks with Arca.Config
    register_callbacks_result =
      try do
        Arca.Cli.register_config_callbacks()
      rescue
        e ->
          Logger.error("Error registering callbacks during initialization: #{inspect(e)}")
          {:error, :initialization_failed, "Failed to register callbacks"}
      end

    end_time = System.monotonic_time(:millisecond)
    # duration = end_time - start_time

    # Log initialization results and update state
    new_state =
      case {load_settings_result, register_callbacks_result} do
        {{:ok, _}, :ok} ->
          # Logger.info("CLI initialization completed successfully in #{duration}ms")
          # Clear initialization flag since we're done initializing
          Arca.Cli.clear_initialization_phase()
          %{initialized: true, initialization_time: end_time}

        _ ->
          Logger.error(
            "CLI initialization failed: settings=#{inspect(load_settings_result)}, callbacks=#{inspect(register_callbacks_result)}"
          )

          # Keep initialization flag set since we failed to initialize
          %{
            initialized: false,
            initialization_time: end_time,
            errors: [load_settings_result, register_callbacks_result]
          }
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end
end
