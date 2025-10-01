defmodule Arca.Cli.CliFixturesDemoTest do
  @moduledoc """
  Demonstration of CLI fixtures testing framework.

  This test file shows how to use the Arca.Cli.Testing.CliFixturesTest module
  to create declarative, file-based CLI tests.

  ## How It Works

  1. Add `use Arca.Cli.Testing.CliFixturesTest` to your test module
  2. Create fixture files in test/cli/fixtures/<command>/<variation>/
  3. Run `mix test` - tests are auto-discovered and generated!

  ## Example Fixtures

  See test/cli/fixtures/ for examples:
  - about/001/ - Simple exact match
  - history/001/ - With setup and teardown
  - cli.status/001/ - Pattern matching for dynamic content

  ## Creating Your Own Fixtures

  1. Choose a command to test: `my.command`
  2. Create directory: test/cli/fixtures/my.command/001/
  3. Create cmd.cli with your command:
     ```
     my.command --flag value
     ```
  4. Optionally create expected.out:
     ```
     Expected output
     Can use {{*}} patterns
     ```
  5. Run: mix test test/arca_cli/cli/fixtures/cli_fixtures_demo_test.exs

  For full documentation, see: `Arca.Cli.Testing.CliFixturesTest`
  """

  use ExUnit.Case, async: false
  use Arca.Cli.Testing.CliFixturesTest

  # That's it! Tests are automatically discovered from test/cli/fixtures/
  # and individual test cases are generated for each fixture variation.
  #
  # Run: mix test test/arca_cli/cli/fixtures/cli_fixtures_demo_test.exs
  # to see the generated tests in action.
end
