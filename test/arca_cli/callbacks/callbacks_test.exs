defmodule Arca.Cli.CallbacksTest do
  use ExUnit.Case, async: false
  alias Arca.Cli.Callbacks

  # Reset callbacks before and after each test
  setup do
    original_callbacks = Application.get_env(:arca_cli, :callbacks, %{})
    Application.put_env(:arca_cli, :callbacks, %{})

    on_exit(fn ->
      Application.put_env(:arca_cli, :callbacks, original_callbacks)
    end)

    :ok
  end

  describe "register/2" do
    test "registers a callback for an event" do
      callback_fn = fn x -> x <> " World" end
      assert Callbacks.register(:test_event, callback_fn) == :ok
      
      callbacks = Application.get_env(:arca_cli, :callbacks, %{})
      assert Map.has_key?(callbacks, :test_event)
      assert [^callback_fn] = Map.get(callbacks, :test_event)
    end

    test "adds multiple callbacks in registration order" do
      callback1 = fn x -> x <> " First" end
      callback2 = fn x -> x <> " Second" end
      
      Callbacks.register(:test_event, callback1)
      Callbacks.register(:test_event, callback2)
      
      callbacks = Application.get_env(:arca_cli, :callbacks, %{})
      assert [^callback2, ^callback1] = Map.get(callbacks, :test_event)
    end
  end

  describe "has_callbacks?/1" do
    test "returns false when no callbacks are registered" do
      refute Callbacks.has_callbacks?(:test_event)
    end

    test "returns true when callbacks are registered" do
      Callbacks.register(:test_event, fn x -> x end)
      assert Callbacks.has_callbacks?(:test_event)
    end
  end

  describe "execute/2" do
    test "returns initial value when no callbacks are registered" do
      initial = "Hello"
      assert Callbacks.execute(:test_event, initial) == initial
    end

    test "executes a single callback" do
      Callbacks.register(:test_event, fn x -> x <> " World" end)
      assert Callbacks.execute(:test_event, "Hello") == "Hello World"
    end

    test "executes multiple callbacks in reverse registration order" do
      Callbacks.register(:test_event, fn x -> x <> " First" end)
      Callbacks.register(:test_event, fn x -> x <> " Second" end)
      
      assert Callbacks.execute(:test_event, "Hello") == "Hello Second First"
    end

    test "supports {:cont, value} to continue the chain" do
      Callbacks.register(:test_event, fn x -> {:cont, x <> " First"} end)
      Callbacks.register(:test_event, fn x -> {:cont, x <> " Second"} end)
      
      assert Callbacks.execute(:test_event, "Hello") == "Hello Second First"
    end

    test "supports {:halt, result} to stop the chain" do
      Callbacks.register(:test_event, fn _x -> "This will never be reached" end)
      Callbacks.register(:test_event, fn x -> {:halt, "Halted at: " <> x} end)
      Callbacks.register(:test_event, fn x -> x <> " First" end)
      
      assert Callbacks.execute(:test_event, "Hello") == "Halted at: Hello First"
    end

    test "handles non-tagged returns as continuation" do
      Callbacks.register(:test_event, fn x -> x <> " First" end)
      Callbacks.register(:test_event, fn x -> x <> " Second" end)
      
      assert Callbacks.execute(:test_event, "Hello") == "Hello Second First"
    end
  end
end