defmodule Arca.Cli.Commands.InputProvider do
  @moduledoc """
  GenServer implementing the Erlang IO protocol to provide scripted stdin.

  Used by cli.script heredoc feature to inject input into interactive commands.

  ## Usage

      {:ok, provider} = InputProvider.start_link(["line 1", "line 2"])
      original_leader = Process.group_leader()
      Process.group_leader(self(), provider)

      # Now IO.gets/1 receives lines from the provider
      line = IO.gets("prompt> ")  # Returns "line 1\\n"

      Process.group_leader(self(), original_leader)
      GenServer.stop(provider)

  ## How It Works

  Implements the Erlang IO protocol by handling `:io_request` messages.
  When a process calls `IO.gets/1`, the request goes to the group leader.
  By setting InputProvider as group leader, we intercept and provide scripted responses.

  Returns `:eof` when lines are exhausted, simulating Ctrl-D.
  """

  use GenServer

  require Logger

  # Client API

  @spec start_link([String.t()]) :: GenServer.on_start()
  def start_link(lines) when is_list(lines) do
    GenServer.start_link(__MODULE__, {lines, 0})
  end

  # Server Callbacks

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_info({:io_request, from, reply_as, req}, state) do
    {reply, new_state} = handle_io_request(req, state)
    send(from, {:io_reply, reply_as, reply})
    {:noreply, new_state}
  end

  def handle_info(msg, state) do
    Logger.debug("InputProvider received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  # IO Protocol Implementation - get_line variants

  defp handle_io_request({:get_line, _encoding, _prompt}, state) do
    get_next_line(state)
  end

  defp handle_io_request({:get_line, _prompt}, state) do
    get_next_line(state)
  end

  # IO Protocol Implementation - get_chars variants

  defp handle_io_request({:get_chars, _encoding, _prompt, count}, state) do
    get_next_chars(count, state)
  end

  defp handle_io_request({:get_chars, _prompt, count}, state) do
    get_next_chars(count, state)
  end

  # IO Protocol Implementation - get_until (treat as get_line)

  defp handle_io_request({:get_until, _encoding, _prompt, _mod, _fn, _args}, state) do
    get_next_line(state)
  end

  defp handle_io_request({:get_until, _prompt, _mod, _fn, _args}, state) do
    get_next_line(state)
  end

  # IO Protocol Implementation - put_chars (pass through)

  defp handle_io_request({:put_chars, _encoding, _chars}, state) do
    {:ok, state}
  end

  defp handle_io_request({:put_chars, _chars}, state) do
    {:ok, state}
  end

  # IO Protocol Implementation - geometry (not supported)

  defp handle_io_request({:get_geometry, _}, state) do
    {{:error, :enotsup}, state}
  end

  # IO Protocol Implementation - multiple requests

  defp handle_io_request({:requests, requests}, state) when is_list(requests) do
    requests
    |> Enum.reduce_while({:ok, state}, fn req, {:ok, acc_state} ->
      case handle_io_request(req, acc_state) do
        {{:error, _} = error, _} -> {:halt, error}
        result -> {:cont, result}
      end
    end)
  end

  # Unknown requests

  defp handle_io_request(req, state) do
    Logger.debug("InputProvider unsupported IO request: #{inspect(req)}")
    {{:error, :enotsup}, state}
  end

  # Get next line with newline appended

  defp get_next_line({lines, index}) when index < length(lines) do
    lines
    |> Enum.at(index)
    |> append_newline()
    |> then(&{&1, {lines, index + 1}})
  end

  defp get_next_line({lines, index}), do: {:eof, {lines, index}}

  # Get next N characters

  defp get_next_chars(_count, {lines, index}) when index >= length(lines) do
    {:eof, {lines, index}}
  end

  defp get_next_chars(count, {lines, index}) do
    lines
    |> Enum.at(index)
    |> extract_chars(count)
    |> build_chars_response(lines, index)
  end

  # Extract requested characters from line

  defp extract_chars(line, count) when byte_size(line) >= count do
    {String.slice(line, 0, count), String.slice(line, count..-1//1)}
  end

  defp extract_chars(line, _count), do: {line, ""}

  # Build response for get_chars

  defp build_chars_response({chars, ""}, lines, index) do
    {append_newline(chars), {lines, index + 1}}
  end

  defp build_chars_response({chars, _remaining}, lines, index) do
    {chars, {lines, index}}
  end

  # Helpers

  defp append_newline(str), do: str <> "\n"
end
