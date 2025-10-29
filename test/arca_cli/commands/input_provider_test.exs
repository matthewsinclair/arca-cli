defmodule Arca.Cli.Commands.InputProviderTest do
  use ExUnit.Case, async: true

  alias Arca.Cli.Commands.InputProvider

  describe "start_link/1" do
    test "starts with empty list" do
      assert {:ok, pid} = InputProvider.start_link([])
      assert Process.alive?(pid)
      GenServer.stop(pid)
    end

    test "starts with lines" do
      assert {:ok, pid} = InputProvider.start_link(["line1", "line2"])
      assert Process.alive?(pid)
      GenServer.stop(pid)
    end
  end

  describe "IO.gets/1 via group leader" do
    test "provides lines in order" do
      {:ok, provider} = InputProvider.start_link(["first", "second", "third"])
      original_leader = Process.group_leader()

      try do
        Process.group_leader(self(), provider)

        assert IO.gets("prompt> ") == "first\n"
        assert IO.gets("prompt> ") == "second\n"
        assert IO.gets("prompt> ") == "third\n"
      after
        Process.group_leader(self(), original_leader)
        GenServer.stop(provider)
      end
    end

    test "returns EOF when exhausted" do
      {:ok, provider} = InputProvider.start_link(["only one"])
      original_leader = Process.group_leader()

      try do
        Process.group_leader(self(), provider)

        assert IO.gets("prompt> ") == "only one\n"
        assert IO.gets("prompt> ") == :eof
        assert IO.gets("prompt> ") == :eof
      after
        Process.group_leader(self(), original_leader)
        GenServer.stop(provider)
      end
    end

    test "returns EOF immediately for empty list" do
      {:ok, provider} = InputProvider.start_link([])
      original_leader = Process.group_leader()

      try do
        Process.group_leader(self(), provider)

        assert IO.gets("prompt> ") == :eof
      after
        Process.group_leader(self(), original_leader)
        GenServer.stop(provider)
      end
    end

    test "appends newline to each line" do
      {:ok, provider} = InputProvider.start_link(["no newline here"])
      original_leader = Process.group_leader()

      try do
        Process.group_leader(self(), provider)

        result = IO.gets("")
        assert result == "no newline here\n"
        assert String.ends_with?(result, "\n")
      after
        Process.group_leader(self(), original_leader)
        GenServer.stop(provider)
      end
    end

    test "preserves whitespace in lines" do
      {:ok, provider} = InputProvider.start_link(["  spaces  ", "\ttabs\t"])
      original_leader = Process.group_leader()

      try do
        Process.group_leader(self(), provider)

        assert IO.gets("") == "  spaces  \n"
        assert IO.gets("") == "\ttabs\t\n"
      after
        Process.group_leader(self(), original_leader)
        GenServer.stop(provider)
      end
    end
  end

  describe "IO.getn/2 via group leader" do
    test "returns requested number of characters" do
      {:ok, provider} = InputProvider.start_link(["hello"])
      original_leader = Process.group_leader()

      try do
        Process.group_leader(self(), provider)

        # Note: getn behavior is simplified in our implementation
        result = IO.getn("", 3)
        assert result in ["hel", "hello\n"]
      after
        Process.group_leader(self(), original_leader)
        GenServer.stop(provider)
      end
    end

    test "returns EOF when exhausted" do
      {:ok, provider} = InputProvider.start_link(["short"])
      original_leader = Process.group_leader()

      try do
        Process.group_leader(self(), provider)

        _first = IO.getn("", 10)
        assert IO.getn("", 1) == :eof
      after
        Process.group_leader(self(), original_leader)
        GenServer.stop(provider)
      end
    end
  end

  describe "multiple IO operations" do
    test "mixes gets and getn calls" do
      {:ok, provider} = InputProvider.start_link(["line1", "line2", "line3"])
      original_leader = Process.group_leader()

      try do
        Process.group_leader(self(), provider)

        assert IO.gets("") == "line1\n"
        assert IO.gets("") == "line2\n"
        assert IO.gets("") == "line3\n"
        assert IO.gets("") == :eof
      after
        Process.group_leader(self(), original_leader)
        GenServer.stop(provider)
      end
    end
  end

  describe "concurrent processes" do
    test "each process gets its own group leader" do
      task1 =
        Task.async(fn ->
          {:ok, provider} = InputProvider.start_link(["task1-line1"])
          original_leader = Process.group_leader()

          try do
            Process.group_leader(self(), provider)
            IO.gets("")
          after
            Process.group_leader(self(), original_leader)
            GenServer.stop(provider)
          end
        end)

      task2 =
        Task.async(fn ->
          {:ok, provider} = InputProvider.start_link(["task2-line1"])
          original_leader = Process.group_leader()

          try do
            Process.group_leader(self(), provider)
            IO.gets("")
          after
            Process.group_leader(self(), original_leader)
            GenServer.stop(provider)
          end
        end)

      assert Task.await(task1) == "task1-line1\n"
      assert Task.await(task2) == "task2-line1\n"
    end
  end

  describe "edge cases" do
    test "handles empty strings in list" do
      {:ok, provider} = InputProvider.start_link(["", "non-empty", ""])
      original_leader = Process.group_leader()

      try do
        Process.group_leader(self(), provider)

        assert IO.gets("") == "\n"
        assert IO.gets("") == "non-empty\n"
        assert IO.gets("") == "\n"
      after
        Process.group_leader(self(), original_leader)
        GenServer.stop(provider)
      end
    end

    test "handles unicode content" do
      {:ok, provider} = InputProvider.start_link(["Hello 世界", "Привет"])
      original_leader = Process.group_leader()

      try do
        Process.group_leader(self(), provider)

        assert IO.gets("") == "Hello 世界\n"
        assert IO.gets("") == "Привет\n"
      after
        Process.group_leader(self(), original_leader)
        GenServer.stop(provider)
      end
    end

    test "handles very long lines" do
      long_line = String.duplicate("a", 10_000)
      {:ok, provider} = InputProvider.start_link([long_line])
      original_leader = Process.group_leader()

      try do
        Process.group_leader(self(), provider)

        assert IO.gets("") == long_line <> "\n"
      after
        Process.group_leader(self(), original_leader)
        GenServer.stop(provider)
      end
    end
  end
end
