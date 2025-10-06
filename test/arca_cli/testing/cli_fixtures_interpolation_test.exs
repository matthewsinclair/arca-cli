defmodule Arca.Cli.Testing.CliFixturesInterpolationTest do
  use ExUnit.Case, async: true

  import Arca.Cli.Testing.CliFixturesTest

  describe "interpolate_bindings/2 - basic variable replacement" do
    test "replaces simple variable" do
      assert interpolate_bindings("User: {{name}}", %{name: "Alice"}) == "User: Alice"
    end

    test "replaces multiple variables" do
      result = interpolate_bindings("{{greeting}} {{name}}", %{greeting: "Hello", name: "Bob"})
      assert result == "Hello Bob"
    end

    test "handles variables in different positions" do
      assert interpolate_bindings("{{prefix}}middle{{suffix}}", %{
               prefix: "start-",
               suffix: "-end"
             }) == "start-middle-end"
    end

    test "replaces same variable multiple times" do
      result = interpolate_bindings("{{name}} said hello to {{name}}", %{name: "Charlie"})
      assert result == "Charlie said hello to Charlie"
    end
  end

  describe "interpolate_bindings/2 - type conversion" do
    test "converts integer to string" do
      assert interpolate_bindings("ID: {{id}}", %{id: 42}) == "ID: 42"
    end

    test "converts boolean true to string" do
      assert interpolate_bindings("Active: {{active}}", %{active: true}) == "Active: true"
    end

    test "converts boolean false to string" do
      assert interpolate_bindings("Active: {{active}}", %{active: false}) == "Active: false"
    end

    test "converts atom to string" do
      assert interpolate_bindings("Status: {{status}}", %{status: :published}) ==
               "Status: published"
    end

    test "converts float to string" do
      assert interpolate_bindings("Price: {{price}}", %{price: 99.99}) == "Price: 99.99"
    end

    test "handles negative numbers" do
      assert interpolate_bindings("Value: {{value}}", %{value: -42}) == "Value: -42"
    end
  end

  describe "interpolate_bindings/2 - pattern matcher preservation" do
    test "preserves {{*}} wildcard" do
      assert interpolate_bindings("Status: {{*}}", %{}) == "Status: {{*}}"
    end

    test "preserves {{??}} digit shorthand" do
      assert interpolate_bindings("ID: {{??}}", %{}) == "ID: {{??}}"
    end

    test "preserves {{\\d+}} explicit digits" do
      assert interpolate_bindings("Count: {{\\d+}}", %{}) == "Count: {{\\d+}}"
    end

    test "preserves {{\\w+}} word characters" do
      assert interpolate_bindings("Name: {{\\w+}}", %{}) == "Name: {{\\w+}}"
    end

    test "preserves {{.*}} greedy wildcard" do
      assert interpolate_bindings("Message: {{.*}}", %{}) == "Message: {{.*}}"
    end

    test "preserves multiple different patterns" do
      result = interpolate_bindings("{{*}} - {{??}} - {{\\d+}}", %{})
      assert result == "{{*}} - {{??}} - {{\\d+}}"
    end

    test "preserves patterns with bindings present" do
      result = interpolate_bindings("{{*}} - {{name}}", %{name: "test"})
      assert result == "{{*}} - test"
    end
  end

  describe "interpolate_bindings/2 - combined scenarios" do
    test "replaces variables while preserving patterns" do
      result =
        interpolate_bindings("User: {{name}}\nCreated: {{*}}\nID: {{\\d+}}", %{name: "Alice"})

      assert result == "User: Alice\nCreated: {{*}}\nID: {{\\d+}}"
    end

    test "handles text with both variables and patterns in complex layout" do
      template = """
      Site: {{site_name}}
      Subdomain: {{subdomain}}
      Status: {{\\w+}}
      Created: {{*}}
      User count: {{user_count}}
      """

      result =
        interpolate_bindings(template, %{
          site_name: "My Site",
          subdomain: "mysite",
          user_count: 42
        })

      expected = """
      Site: My Site
      Subdomain: mysite
      Status: {{\\w+}}
      Created: {{*}}
      User count: 42
      """

      assert result == expected
    end

    test "handles multiple variables and patterns on same line" do
      result =
        interpolate_bindings("{{name}}: {{*}} ({{count}} items)", %{name: "Total", count: 5})

      assert result == "Total: {{*}} (5 items)"
    end
  end

  describe "interpolate_bindings/2 - missing bindings" do
    test "leaves unknown variables as literal {{key}}" do
      assert interpolate_bindings("{{unknown}}", %{}) == "{{unknown}}"
    end

    test "replaces known and leaves unknown" do
      result = interpolate_bindings("{{name}} and {{other}}", %{name: "Alice"})
      assert result == "Alice and {{other}}"
    end

    test "handles empty bindings map" do
      assert interpolate_bindings("{{name}}", %{}) == "{{name}}"
    end

    test "handles nil-like variable names gracefully" do
      result = interpolate_bindings("{{missing_key}}", %{present: "value"})
      assert result == "{{missing_key}}"
    end
  end

  describe "interpolate_bindings/2 - edge cases" do
    test "handles empty string" do
      assert interpolate_bindings("", %{name: "Alice"}) == ""
    end

    test "handles string with no placeholders" do
      assert interpolate_bindings("plain text", %{name: "Alice"}) == "plain text"
    end

    test "handles single braces (not placeholders)" do
      assert interpolate_bindings("{single} or }reversed{", %{}) == "{single} or }reversed{"
    end

    test "handles nested braces (not valid placeholders)" do
      assert interpolate_bindings("{{{nested}}}", %{nested: "value"}) == "{value}"
    end

    test "handles special regex characters in values" do
      result = interpolate_bindings("Pattern: {{pattern}}", %{pattern: ".*+?"})
      assert result == "Pattern: .*+?"
    end

    test "handles newlines in content" do
      result = interpolate_bindings("Line 1: {{a}}\nLine 2: {{b}}", %{a: "first", b: "second"})
      assert result == "Line 1: first\nLine 2: second"
    end

    test "handles variables with underscores" do
      result = interpolate_bindings("{{user_id}} {{api_key}}", %{user_id: 123, api_key: "abc"})
      assert result == "123 abc"
    end

    test "handles variables with numbers" do
      result = interpolate_bindings("{{var1}} {{var2}}", %{var1: "first", var2: "second"})
      assert result == "first second"
    end

    test "handles case sensitivity (lowercase only)" do
      result = interpolate_bindings("{{name}} {{NAME}}", %{name: "lower"})
      # {{NAME}} should work too due to case-insensitive regex
      assert result == "lower {{NAME}}"
    end

    test "handles very long content" do
      long_text = String.duplicate("word ", 1000) <> "{{name}}"
      result = interpolate_bindings(long_text, %{name: "end"})
      assert String.ends_with?(result, "end")
    end

    test "preserves whitespace around placeholders" do
      result = interpolate_bindings("  {{name}}  ", %{name: "test"})
      assert result == "  test  "
    end

    test "handles consecutive placeholders" do
      result = interpolate_bindings("{{a}}{{b}}{{c}}", %{a: "1", b: "2", c: "3"})
      assert result == "123"
    end
  end

  describe "interpolate_bindings/2 - optimization" do
    test "returns content unchanged when bindings are empty (fast path)" do
      content = "Some {{*}} content with {{name}} placeholder"
      result = interpolate_bindings(content, %{})
      assert result == content
    end
  end

  describe "interpolate_bindings/2 - real-world scenarios" do
    test "CLI command interpolation" do
      result =
        interpolate_bindings("laksa.auth.login --api-key \"{{api_key}}\"", %{
          api_key: "laksa_abc123"
        })

      assert result == "laksa.auth.login --api-key \"laksa_abc123\""
    end

    test "expected output with mixed patterns and variables" do
      template = """
      Authenticated successfully
      User: {{user_email}}
      ID: {{user_id}}
      Token: {{*}}
      Expires: {{\\d+}}
      """

      result =
        interpolate_bindings(template, %{
          user_email: "test@example.com",
          user_id: 42
        })

      expected = """
      Authenticated successfully
      User: test@example.com
      ID: 42
      Token: {{*}}
      Expires: {{\\d+}}
      """

      assert result == expected
    end

    test "table output with dynamic columns" do
      template = """
      Site List ({{count}} sites)

      {{site_1}} | {{*}} | {{\\w+}}
      {{site_2}} | {{*}} | {{\\w+}}
      """

      result =
        interpolate_bindings(template, %{
          count: 2,
          site_1: "mysite",
          site_2: "other"
        })

      expected = """
      Site List (2 sites)

      mysite | {{*}} | {{\\w+}}
      other | {{*}} | {{\\w+}}
      """

      assert result == expected
    end
  end
end
