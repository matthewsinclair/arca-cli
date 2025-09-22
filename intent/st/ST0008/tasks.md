# Tasks - ST0008: Orthogonalised formatting and outputting

## Progress Summary

**Overall Status**: 20% Complete (2 of 10 work packages)

- ✅ Completed: WP1 (Context Module), WP2 (Plain Renderer) - See done.md
- 🎯 Ready to Start: WP3 (Fancy Renderer), WP7 (Global Options)
- ⏸️ Blocked: WP4-WP6, WP8-WP10 (waiting on dependencies)

## Remaining Work Packages

### WP3: Fancy Renderer Implementation

**Status**: Ready to Start
**Size**: M
**Description**: Implement the fancy renderer with colors, symbols, and Owl formatting.

**Tasks**:

- [ ] Create `lib/arca_cli/output/fancy_renderer.ex`
- [ ] Implement colored message renderers (success, error, warning, info)
- [ ] Implement Owl.Table integration for `{:table, rows, opts}`
- [ ] Implement formatted lists with colored bullets
- [ ] Implement spinner support for `{:spinner, label, func}`
- [ ] Handle non-TTY fallback to plain renderer
- [ ] Add tests with Owl output verification
- [ ] Document color scheme and symbols used

---

### WP4: Output Module Pipeline

**Status**: Blocked (requires WP3)
**Size**: M
**Description**: Create the main `Arca.Cli.Output` module that orchestrates the rendering pipeline.

**Tasks**:

- [ ] Create `lib/arca_cli/output.ex`
- [ ] Implement `render/1` main entry point
- [ ] Implement `determine_style/1` for auto-detection logic
- [ ] Implement `apply_renderer/1` to dispatch to correct renderer
- [ ] Implement `format_for_output/1` to prepare final string
- [ ] Add support for NO_COLOR environment variable
- [ ] Add support for MIX_ENV=test detection
- [ ] Add TTY detection via `Owl.IO.terminal?/0`
- [ ] Create comprehensive pipeline tests
- [ ] Test style detection in various environments

---

### WP5: Callback Integration

**Status**: Blocked (requires WP4)
**Size**: S
**Description**: Register new callback points and integrate with existing callback system.

**Tasks**:

- [ ] Add `:format_command_result` callback documentation to Callbacks module
- [ ] Create registration helper in application startup
- [ ] Implement `format_result/1` function in Output module
- [ ] Test callback chain with multiple formatters
- [ ] Ensure backwards compatibility with existing `:format_output` callback
- [ ] Add examples to callback documentation

---

### WP6: Command Execution Integration

**Status**: Blocked (requires WP4)
**Size**: M
**Description**: Update `Arca.Cli.execute_command/5` to handle Ctx returns while maintaining backwards compatibility.

**Tasks**:

- [ ] Modify `execute_command/5` to check return type
- [ ] Add Ctx detection and rendering path
- [ ] Preserve existing behavior for string returns
- [ ] Preserve existing behavior for {:nooutput, _} tuples
- [ ] Preserve existing behavior for error tuples
- [ ] Add integration tests for all return types
- [ ] Update error handling to work with Ctx
- [ ] Ensure REPL mode compatibility

---

### WP7: Global CLI Options

**Status**: Ready to Start (independent)
**Size**: S
**Description**: Add global `--style` and `--no-ansi` options to CLI configuration.

**Tasks**:

- [ ] Add `--style` option to global Optimus configuration
- [ ] Add `--no-ansi` as alias for `--style plain`
- [ ] Pass style option through to context metadata
- [ ] Update help text generation
- [ ] Add option parsing tests
- [ ] Document new options in README
- [ ] Add examples to user guide

---

### WP8: Sample Command Migration

**Status**: Blocked (requires WP6)
**Size**: S
**Description**: Migrate `AboutCommand` to use Ctx as proof of concept and example.

**Tasks**:

- [ ] Update AboutCommand to return Ctx
- [ ] Use appropriate output types (info, list, etc.)
- [ ] Test both fancy and plain output modes
- [ ] Verify backwards compatibility
- [ ] Create migration guide based on experience
- [ ] Document patterns and best practices

---

### WP9: Test Infrastructure Updates

**Status**: Blocked (requires WP6)
**Size**: M
**Description**: Update test helpers and fixtures to support both output styles.

**Tasks**:

- [ ] Create test helper for asserting Ctx output
- [ ] Add matcher for plain text output
- [ ] Add matcher for structured output items
- [ ] Update existing test helpers to handle Ctx
- [ ] Create fixture comparison utilities
- [ ] Add environment variable test helpers
- [ ] Document testing patterns for command authors

---

### WP10: Documentation Package

**Status**: Blocked (requires all other WPs)
**Size**: S
**Description**: Create comprehensive documentation for command authors.

**Tasks**:

- [ ] Write migration guide from string to Ctx returns
- [ ] Create output type reference documentation
- [ ] Add cookbook examples for common patterns
- [ ] Update BaseCommand documentation
- [ ] Add troubleshooting guide
- [ ] Create quick reference card
- [ ] Update README with new features

---

## Dependencies Graph

```
WP1 ✅ ──┬──> WP3 🎯 ──> WP4 ──┬──> WP5
        │                      ├──> WP6 ──┬──> WP8
WP2 ✅ ──┘                      │          └──> WP9
                               └──> WP10
WP7 🎯 (independent)
```

## Next Steps

1. **Start WP3 (Fancy Renderer)** - Build on PlainRenderer pattern with colors and formatting
2. **Start WP7 (Global Options)** - Can be done in parallel, no dependencies
3. **Then WP4 (Output Pipeline)** - Once WP3 is complete, create the orchestration layer

## Success Metrics

- [ ] All existing tests pass without modification
- [ ] New commands can use Ctx with structured output
- [ ] Plain mode produces no ANSI codes
- [ ] Test fixtures work in both modes
- [ ] Performance regression < 5%
- [ ] Zero breaking changes for existing commands
- [ ] Documentation coverage for all new APIs
