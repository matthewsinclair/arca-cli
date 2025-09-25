defmodule Arca.Cli.CommandMatcherTest do
  use ExUnit.Case, async: true
  alias Arca.Cli.CommandMatcher

  @sample_commands [
    "about",
    "cfg.get",
    "cfg.help",
    "cfg.list",
    "cli.debug",
    "cli.error",
    "cli.history",
    "cli.redo",
    "cli.script",
    "cli.status",
    "dev.deps",
    "dev.info",
    "ll",
    "ll.agent.create",
    "ll.agent.engage",
    "ll.agent.list",
    "ll.config.reset",
    "ll.desc.character",
    "ll.list.characters",
    "ll.list.locations",
    "ll.llm.chat",
    "ll.llm.config",
    "ll.llm.config.provider",
    "ll.llm.ping",
    "ll.world.list",
    "ll.world.load",
    "ll.world.mount",
    "ll.world.status",
    "ll.world.unmount",
    "settings.all",
    "settings.get",
    "sys.cmd",
    "sys.flush",
    "sys.info"
  ]

  describe "fuzzy_match/2" do
    test "returns single match for exact command" do
      assert {:single, "about"} = CommandMatcher.fuzzy_match("about", @sample_commands)
      assert {:single, "cli.debug"} = CommandMatcher.fuzzy_match("cli.debug", @sample_commands)
    end

    test "returns single match for suffix matching" do
      assert {:single, "ll.agent.engage"} = CommandMatcher.fuzzy_match("engage", @sample_commands)
      assert {:single, "cli.debug"} = CommandMatcher.fuzzy_match("debug", @sample_commands)
    end

    test "returns single match for partial namespace" do
      assert {:single, "ll.world.load"} = CommandMatcher.fuzzy_match("world.load", @sample_commands)
      assert {:single, "ll.agent.engage"} = CommandMatcher.fuzzy_match("agent.engage", @sample_commands)
    end

    test "returns multiple matches when ambiguous" do
      result = CommandMatcher.fuzzy_match("agent", @sample_commands)
      assert {:multiple, matches} = result
      assert "ll.agent.create" in matches
      assert "ll.agent.engage" in matches
      assert "ll.agent.list" in matches
    end

    test "returns multiple matches for namespace prefix" do
      result = CommandMatcher.fuzzy_match("world", @sample_commands)
      assert {:multiple, matches} = result
      assert "ll.world.list" in matches
      assert "ll.world.load" in matches
      assert "ll.world.mount" in matches
      assert "ll.world.status" in matches
      assert "ll.world.unmount" in matches
    end

    test "returns no match for non-existent commands" do
      assert :no_match = CommandMatcher.fuzzy_match("nonexistent", @sample_commands)
      assert :no_match = CommandMatcher.fuzzy_match("xyz123", @sample_commands)
    end

    test "handles abbreviation matching" do
      # This tests if "llm.conf" can match "ll.llm.config"
      # Since both ll.llm.config and ll.llm.config.provider match,
      # we should get multiple matches
      result = CommandMatcher.fuzzy_match("llm.conf", @sample_commands)
      assert {:multiple, matches} = result
      assert "ll.llm.config" in matches
      assert "ll.llm.config.provider" in matches
    end

    test "prioritizes exact suffix matches" do
      # "flush" should match sys.flush even though it appears in other contexts
      assert {:single, "sys.flush"} = CommandMatcher.fuzzy_match("flush", @sample_commands)
    end

    test "handles empty input gracefully" do
      assert :no_match = CommandMatcher.fuzzy_match("", @sample_commands)
    end

    test "handles empty command list gracefully" do
      assert :no_match = CommandMatcher.fuzzy_match("test", [])
    end

    test "is case insensitive" do
      assert {:single, "about"} = CommandMatcher.fuzzy_match("ABOUT", @sample_commands)
      assert {:single, "ll.agent.engage"} = CommandMatcher.fuzzy_match("ENGAGE", @sample_commands)
    end
  end

  describe "score_match/2" do
    test "scores exact matches highest" do
      assert 1.0 = CommandMatcher.score_match("about", "about")
    end

    test "scores suffix matches high" do
      score = CommandMatcher.score_match("engage", "ll.agent.engage")
      assert score > 0.9
    end

    test "scores partial namespace matches well" do
      score = CommandMatcher.score_match("agent.create", "ll.agent.create")
      assert score > 0.8
    end

    test "scores non-matches as zero" do
      assert CommandMatcher.score_match("xyz", "about") == 0.0
    end
  end

  describe "partial_namespace_match?/2" do
    test "returns true for valid partial namespaces" do
      assert CommandMatcher.partial_namespace_match?("agent.create", "ll.agent.create")
      assert CommandMatcher.partial_namespace_match?("world.load", "ll.world.load")
    end

    test "returns false for non-matching namespaces" do
      refute CommandMatcher.partial_namespace_match?("agent.create", "ll.world.load")
      refute CommandMatcher.partial_namespace_match?("foo.bar", "ll.agent.create")
    end

    test "returns false when input is longer than command" do
      refute CommandMatcher.partial_namespace_match?("ll.agent.create.extra", "ll.agent.create")
    end
  end

  describe "abbreviation_match?/2" do
    test "returns true for valid abbreviations" do
      assert CommandMatcher.abbreviation_match?("llm.conf", "ll.llm.config")
      assert CommandMatcher.abbreviation_match?("ll.ag", "ll.agent")
    end

    test "returns false for non-abbreviations" do
      refute CommandMatcher.abbreviation_match?("xyz", "ll.agent.create")
      refute CommandMatcher.abbreviation_match?("agent.xyz", "ll.agent.create")
    end
  end

  describe "edit_distance/2" do
    test "calculates correct edit distance" do
      assert 0 = CommandMatcher.edit_distance("hello", "hello")
      assert 1 = CommandMatcher.edit_distance("hello", "helo")
      assert 1 = CommandMatcher.edit_distance("hello", "hell")
      assert 1 = CommandMatcher.edit_distance("hello", "hllo")  # One deletion of 'e'
      assert 5 = CommandMatcher.edit_distance("hello", "bye")   # All characters need to change
    end
  end

  describe "format_multiple_matches/1" do
    test "formats multiple matches correctly" do
      matches = ["ll.agent.create", "ll.agent.engage", "ll.agent.list"]
      formatted = CommandMatcher.format_multiple_matches(matches)

      assert formatted =~ "? Did you mean:"
      assert formatted =~ "1. ll.agent.create"
      assert formatted =~ "2. ll.agent.engage"
      assert formatted =~ "3. ll.agent.list"
    end
  end
end