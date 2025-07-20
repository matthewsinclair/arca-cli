# Arca CLI Development Guidelines

## Build Commands

- Format code: `mix format`
- Run all tests: `./scripts/test`
- Run single test: `./scripts/test test/path/to/test_file.exs:line_number`
- Build escript: `mix escript.build`
- Generate docs: `mix docs`

## Code Style

### Organization

- Commands in `lib/arca_cli/commands/`
- Behaviours use `*_behaviour.ex` naming
- Base classes use `base_*.ex` naming

### Types & Documentation

- Document modules with `@moduledoc`
- Specify types with `@type` and type specs with `@spec`
- Use `@callback` for behaviour definitions

### Naming & Formatting

- Use snake_case for variables and functions
- Module names in PascalCase
- Return tuples as `{:ok, result}` or `{:error, reason}`
- Handle configuration via configurator modules

### Testing

- Tests match module structure in `test/` directory
- Use ExUnit with descriptive test names
- Set up test environment in `setup` blocks
- Clean up with `on_exit` callbacks
